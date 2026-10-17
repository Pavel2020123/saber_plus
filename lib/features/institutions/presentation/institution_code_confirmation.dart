import 'package:flutter/material.dart';

/// Una confirmación pertenece a la pantalla/cuenta que la abrió, no a la siguiente.
class InstitutionCodeConfirmation {
  DialogRoute<bool>? _route;

  Future<bool?> show({
    required BuildContext context,
    required WidgetBuilder builder,
  }) async {
    if (_route != null) return false;
    final route = DialogRoute<bool>(context: context, builder: builder);
    _route = route;
    try {
      return await Navigator.of(context).push(route);
    } finally {
      if (identical(_route, route)) _route = null;
    }
  }

  void dispose() {
    final route = _route;
    _route = null;
    // Puede disponerse durante reconstrucción por cambio de sesión. No mutar
    // Navigator mientras está reconstruyendo ni cerrar otra ruta por accidente.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (route != null && route.isActive) route.navigator?.removeRoute(route);
    });
  }
}
