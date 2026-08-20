#!/usr/bin/env python3
"""Generate a product shot with ComfyUI + RealVisXL.

Posts a warm-editorial/rustic product workflow to a running ComfyUI server,
polls until it finishes, and downloads the result into comfyui/output/.

Usage:
    python3 comfyui/run_product_shot.py --prompt "half Hass avocado with pit" --name aguacate
    python3 comfyui/run_product_shot.py --prompt "wedge of manchego cheese" --name queso_manchego
"""
import argparse
import json
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

OUTPUT_DIR = Path(__file__).parent / "output"

STYLE_SUFFIX = (
    "professional food photography, warm natural side lighting, "
    "rustic wooden table background, shallow depth of field, "
    "editorial style, appetizing, high detail"
)
NEGATIVE_PROMPT = (
    "text, watermark, logo, lowres, blurry, deformed, extra limbs, "
    "low quality, worst quality, oversaturated, harsh shadows, plastic"
)


def parse_args():
    parser = argparse.ArgumentParser(description="Generate a product shot via ComfyUI")
    parser.add_argument("--prompt", required=True, help="Product description, e.g. 'half Hass avocado with pit'")
    parser.add_argument("--name", required=True, help="Output filename stem, e.g. 'aguacate'")
    parser.add_argument("--server", default="http://127.0.0.1:8188", help="ComfyUI API base URL")
    return parser.parse_args()


def build_graph(product_prompt):
    checkpoint = "sdxl/RealVisXL_V5.0_fp16.safetensors"
    positive = f"{product_prompt}, {STYLE_SUFFIX}"
    return {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": checkpoint}},
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": positive, "clip": ["1", 1]}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": NEGATIVE_PROMPT, "clip": ["1", 1]}},
        "8": {"class_type": "EmptyLatentImage", "inputs": {"width": 1024, "height": 1024, "batch_size": 1}},
        "9": {
            "class_type": "KSampler",
            "inputs": {
                "model": ["1", 0],
                "positive": ["2", 0],
                "negative": ["3", 0],
                "latent_image": ["8", 0],
                "seed": 2718281828,
                "steps": 28,
                "cfg": 5.0,
                "sampler_name": "dpmpp_2m",
                "scheduler": "karras",
                "denoise": 1.0,
            },
        },
        "4": {"class_type": "VAEDecode", "inputs": {"samples": ["9", 0], "vae": ["1", 2]}},
        "5": {
            "class_type": "SaveImage",
            "inputs": {"images": ["4", 0], "filename_prefix": "mercadomio/product_shot"},
        },
    }


def post_prompt(server, graph):
    req = urllib.request.Request(
        f"{server}/prompt",
        data=json.dumps({"prompt": graph}).encode(),
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())


def wait_for_output(server, prompt_id, timeout=900):
    deadline = time.time() + timeout
    while time.time() < deadline:
        with urllib.request.urlopen(f"{server}/history/{prompt_id}") as resp:
            history = json.loads(resp.read())
        entry = history.get(prompt_id)
        if entry:
            status = entry.get("status", {})
            if status.get("completed"):
                return entry
            if "error" in status:
                raise RuntimeError(f"ComfyUI error: {status['error']}")
        time.sleep(2)
    raise TimeoutError(f"ComfyUI did not finish within {timeout}s")


def download_image(server, image_meta, dest):
    params = urllib.parse.urlencode(
        {
            "filename": image_meta["filename"],
            "subfolder": image_meta.get("subfolder", ""),
            "type": image_meta.get("type", "output"),
        }
    )
    with urllib.request.urlopen(f"{server}/view?{params}") as resp:
        dest.write_bytes(resp.read())
    print(f"Saved {dest} ({dest.stat().st_size / 1024 / 1024:.2f} MB)")


def main():
    args = parse_args()
    graph = build_graph(args.prompt)
    result = post_prompt(args.server, graph)
    prompt_id = result["prompt_id"]
    print(f"Submitted prompt {prompt_id}, waiting...")

    entry = wait_for_output(args.server, prompt_id)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    saved = []
    for node_id, node_out in entry.get("outputs", {}).items():
        for img in node_out.get("images", []):
            dest = OUTPUT_DIR / f"{args.name}.png"
            download_image(args.server, img, dest)
            saved.append(str(dest))
    if not saved:
        print("No images returned; check ComfyUI logs/output dir.", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()