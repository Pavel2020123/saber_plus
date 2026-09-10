/// Compara esquema, host y puerto; no admite credenciales embebidas en la URL.
bool isAllowedApiOrigin(Uri? origin, Uri target) =>
    origin != null &&
    origin.hasAuthority &&
    (origin.scheme == 'https' || origin.scheme == 'http') &&
    target.scheme == origin.scheme &&
    target.host == origin.host &&
    target.port == origin.port &&
    target.userInfo.isEmpty;
