import 'package:flutter/material.dart';

/// Footer component matching the Stitch design mocks.
///
/// Layout:
/// - (a) Logo + copyright on the left
/// - (b) Legal links centered: [Privacidad, Términos, Preguntas Frecuentes, Contacto]
///
/// Style: `surfaceContainerLow` background with a `outlineVariant` top border.
/// Navigation and link labels use the Public Sans font family (label font).
class Footer extends StatelessWidget {
  const Footer({super.key});

  static const List<String> legalLinks = [
    'Privacidad',
    'Términos',
    'Preguntas Frecuentes',
    'Contacto',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 16,
        vertical: 20,
      ),
      child: isDesktop
          ? _buildDesktopFooter(colorScheme)
          : _buildMobileFooter(colorScheme),
    );
  }

  /// Desktop layout: logo+copyright left, legal links centered.
  Widget _buildDesktopFooter(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildBrand(colorScheme),
        Flexible(child: _buildLegalLinks(colorScheme)),
      ],
    );
  }

  /// Mobile layout: legal links centered first, then brand+copyright below.
  Widget _buildMobileFooter(ColorScheme colorScheme) {
    return Column(
      children: [
        _buildLegalLinks(colorScheme),
        const SizedBox(height: 12),
        _buildBrand(colorScheme),
        const SizedBox(height: 4),
        _buildCopyright(colorScheme),
      ],
    );
  }

  /// (a) Logo + copyright — left-aligned on desktop.
  Widget _buildBrand(ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.storefront,
          size: 20,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Text(
          'Mercadomio',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
            fontFamily: 'Public Sans', // label font per Stitch DS
          ),
        ),
      ],
    );
  }

  Widget _buildCopyright(ColorScheme colorScheme) {
    return Text(
      '© 2024 Mercadomio. Todos los derechos reservados.',
      style: TextStyle(
        fontSize: 13,
        color: colorScheme.onSurfaceVariant,
        fontFamily: 'Public Sans', // label font per Stitch DS
      ),
    );
  }

  /// (b) Legal links centered.
  Widget _buildLegalLinks(ColorScheme colorScheme) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 24,
      runSpacing: 8,
      children: legalLinks.map((label) {
        return Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
            fontFamily: 'Public Sans', // label font per Stitch DS
          ),
        );
      }).toList(),
    );
  }
}
