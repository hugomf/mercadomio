import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos y Condiciones'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Términos y Condiciones',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Última actualización: 11 de septiembre de 2026',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                _section(
                  colorScheme,
                  '1. Aceptación',
                  'Al usar MercadoMío aceptas estos términos. Si no estás de acuerdo, por favor no uses la plataforma.',
                ),
                _section(
                  colorScheme,
                  '2. Cuenta y autenticación',
                  'La autenticación se delega a userbrew (OIDC). Eres responsable de mantener la confidencialidad de tu cuenta y de todas las actividades realizadas con ella.',
                ),
                _section(
                  colorScheme,
                  '3. Pedidos y precios',
                  'Los precios se calculan al momento de crear el pedido e incluyen promociones vigentes (cupones, precio por volumen). El total final se confirma antes del pago. Nos reservamos el derecho de cancelar pedidos por errores de precio o disponibilidad.',
                ),
                _section(
                  colorScheme,
                  '4. Pagos',
                  'Los pagos se procesan de forma segura vía Conekta (hosted checkout). No almacenamos datos de tarjeta. Al confirmar tu pedido serás redirigido a la página segura de pago para completar la transacción con tarjeta, OXXO o SPEI.',
                ),
                _section(
                  colorScheme,
                  '5. Envíos y devoluciones',
                  'Los tiempos de entrega son estimados. Puedes cancelar un pedido en estado pendiente antes de su confirmación. Para devoluciones, contacta soporte dentro de los 30 días posteriores a la entrega.',
                ),
                _section(
                  colorScheme,
                  '6. Privacidad',
                  'Tratamos tus datos conforme a nuestra política de privacidad. Los datos de envío se usan únicamente para procesar y entregar tu pedido.',
                ),
                _section(
                  colorScheme,
                  '7. Contacto',
                  'Dudas o reclamaciones: soporte@mercadomio.mx',
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Pago 100% seguro y encriptado. Tus datos están protegidos.',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(ColorScheme colorScheme, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
