import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/category_service.dart';
import '../../models/category.dart' as models;

class CategoryTree extends StatelessWidget {
  const CategoryTree({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<models.Category>>(
      future: Get.find<CategoryService>().getRootCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No categories found'));
        }
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            return _CategoryNode(
              category: snapshot.data![index],
              depth: 0,
            );
          },
        );
      },
    );
  }
}

class _CategoryNode extends StatefulWidget {
  final models.Category category;
  final int depth;

  const _CategoryNode({
    required this.category,
    required this.depth
  });

  @override
  State<_CategoryNode> createState() => _CategoryNodeState();
}

class _CategoryNodeState extends State<_CategoryNode> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final hasChildren = widget.category.childrenIds?.isNotEmpty ?? false;
    
    return Column(
      children: [
        ListTile(
          leading: hasChildren
              ? IconButton(
                  icon: Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () => setState(() => _expanded = !_expanded),
                )
              : SizedBox(width: 24),
          title: Text(widget.category.name),
          trailing: PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Text('Edit'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
          ),
        ),
        if (_expanded && hasChildren)
          Padding(
            padding: EdgeInsets.only(left: (widget.depth + 1) * 24.0),
            child: FutureBuilder<List<models.Category>>(
              future: Get.find<CategoryService>().getCategories(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                final children = snapshot.data!
                    .where((c) => widget.category.childrenIds!.contains(c.id))
                    .toList();
                return Column(
                  children: children.map((child) => _CategoryNode(
                    category: child,
                    depth: widget.depth + 1,
                  )).toList(),
                );
              },
            ),
          ),
      ],
    );
  }
}