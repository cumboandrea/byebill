class TopService {
  final String id;
  final String name;
  final String logoPath;
  final String? cancellationUrl;
  final String? cancellationText;
  final String? cancellationInstructions;

  const TopService({
    required this.id,
    required this.name,
    required this.logoPath,
    this.cancellationUrl,
    this.cancellationText,
    this.cancellationInstructions,
  });
}

const List<TopService> topServices = [
  TopService(
    id: 'netflix',
    name: 'Netflix',
    logoPath: 'assets/logos/netflix.svg',
    cancellationUrl: 'https://www.netflix.com/cancelplan',
    cancellationText: 'Te llevamos directamente a la página oficial de cancelación de Netflix.',
    cancellationInstructions: 'Perfil → Cuenta → Sección Membresía y facturación → Cancelar membresía → Confirmar baja',
  ),
  TopService(
    id: 'amazon_prime',
    name: 'Amazon Prime',
    logoPath: 'assets/logos/amazon_prime.svg',
    cancellationUrl: 'https://www.amazon.es/mc',
    cancellationText: 'Te llevamos directamente a la gestión de tu suscripción Prime en Amazon.',
    cancellationInstructions: 'Mi cuenta → Suscripción a Prime → Gestionar → Actualizar, cancelar y más → Finalizar membresía',
  ),
  TopService(
    id: 'spotify',
    name: 'Spotify',
    logoPath: 'assets/logos/spotify.svg',
    cancellationUrl: 'https://www.spotify.com/account/cancel/',
    cancellationText: 'Te llevamos a tu cuenta de Spotify para cancelar el plan Premium.',
    cancellationInstructions: 'Login web → Tu plan → Cambiar plan → Desplazar hasta Cancelar Premium → Continuar hasta el fin',
  ),
  TopService(
    id: 'icloud',
    name: 'Apple iCloud+',
    logoPath: 'assets/logos/apple.svg',
    cancellationUrl: 'https://support.apple.com/es-es/HT202039',
    cancellationText: 'Te llevamos directamente al ajuste de Apple ID o gestionamos la cancelación oficial.',
    cancellationInstructions: 'Ajustes de iOS → [Nombre / Apple Account] → Suscripciones → Seleccionar plan → Cancelar suscripción',
  ),
  TopService(
    id: 'hbo_max',
    name: 'HBO Max',
    logoPath: 'assets/logos/hbo.svg',
    cancellationUrl: 'https://auth.max.com/subscription',
    cancellationText: 'Te llevamos a la página de suscripción de HBO Max para cancelarla fácilmente.',
    cancellationInstructions: 'Perfil → Ajustes → Suscripción → Cancelar suscripción. Si fue mediante Apple/Google, redirige a tienda',
  ),
  TopService(
    id: 'movistar_plus',
    name: 'Movistar+',
    logoPath: 'assets/logos/movistarplus.svg',
    cancellationUrl: 'https://ver.movistarplus.es/perfil/suscripcion',
    cancellationText: 'Te llevamos al área de cliente de Movistar+ para gestionar la baja.',
  ),
  TopService(
    id: 'disney_plus',
    name: 'Disney+',
    logoPath: 'assets/logos/disneyplus.svg',
    cancellationUrl: 'https://www.disneyplus.com/account/subscription',
    cancellationText: 'Accede a la sección de suscripción de tu cuenta de Disney+.',
    cancellationInstructions: 'Perfil → Cuenta → Suscripción (seleccionar plan) → Cancelar suscripción → Motivo y confirmación',
  ),
  TopService(
    id: 'youtube_premium',
    name: 'YouTube Premium',
    logoPath: 'assets/logos/youtube.svg',
    cancellationUrl: 'https://www.youtube.com/account/cancel/',
    cancellationText: 'Te llevamos a tu cuenta de YouTube Premium para cancelar el plan Premium.',
    cancellationInstructions: 'Foto de perfil → Compras y membresías → Administrar membresía → Desactivar → Continuar a cancelar',
  ),
  TopService(
    id: 'google_one',
    name: 'Google One',
    logoPath: 'assets/logos/google-one.svg',
    cancellationUrl: 'https://one.google.com/settings',
    cancellationText: 'Accede a la sección de suscripción de tu cuenta de Google One.',
    cancellationInstructions: 'Perfil → Cuenta → Suscripción (seleccionar plan) → Cancelar suscripción → Motivo y confirmación',
  ),
  TopService(
    id: 'microsoft_365',
    name: 'Microsoft 365',
    logoPath: 'assets/logos/microsoft.svg',
    cancellationUrl: 'https://support.microsoft.com/es-es/accounts-billing/subscriptions/cancel-a-microsoft-365-subscription#:~:text=account.microsoft.com/services/microsoft365',
    cancellationText: 'Te llevamos directamente al área de cliente de Microsoft para cancelarla fácilmente.',
    cancellationInstructions: 'Servicios y suscripciones → Administrar junto a Oﬃce 365 → Cancelar o Desactivar facturación periódica',
  ),
  TopService(
    id: 'adobe_creative_cloud',
    name: 'Adobe Creative Cloud',
    logoPath: 'assets/logos/adobe.svg',
    cancellationUrl: 'https://account.adobe.com/plans',
    cancellationText: 'Te llevamos directamente a la página de suscripción de Adobe para cancelarla fácilmente.',
    cancellationInstructions: 'Planes y productos → Administrar plan → Cancelar tu plan → Completar flujo y confirmar penalización (si aplica)',
  ),
  TopService(
    id: 'dazn',
    name: 'DAZN',
    logoPath: 'assets/logos/dazn.svg',
    cancellationUrl: 'https://www.dazn.com/myaccount',
    cancellationText: 'Te llevamos directamente al área de cliente de DAZN.',
    cancellationInstructions: 'Menú → Mi cuenta → Pestaña Suscripción → Cancelar suscripción → Respetar los 30 días de preaviso si aplica',
  ),
  TopService(
    id: 'duolingo_super',
    name: 'Duolingo Super',
    logoPath: 'assets/logos/duolingo.svg',
    cancellationUrl: 'https://www.duolingo.com/',
    cancellationText: 'Te llevamos directamente al área de cliente de Duolingo.',
    cancellationInstructions: 'En web: Ajustes → Super Duolingo → Cancelar. En smartphone: Gestionar desde la sección de suscripciones de iOS/Android',
  ),
  TopService(
    id: 'audible',
    name: 'Audible',
    logoPath: 'assets/logos/audible.svg',
    cancellationUrl: 'https://www.audible.es/account/overview',
    cancellationText: 'Te llevamos directamente al área de cliente de Audible.',
    cancellationInstructions: 'Web versión PC → Detalles de la cuenta → Ver detalles de suscripción → Cancelar membresía',
  ),
  TopService(
    id: 'linkedin_premium',
    name: 'LinkedIn Premium',
    logoPath: 'assets/logos/linkedin.svg',
    cancellationUrl: 'https://www.linkedin.com/premium/manage',
    cancellationText: 'Te llevamos directamente al área de cliente de LinkedIn.',
    cancellationInstructions: 'Icono "Yo" → Ajustes y privacidad → Preferencias de cuenta → Suscripciones → Cancelar suscripción',
  ),
  TopService(
    id: 'chatgpt_plus',
    name: 'ChatGPT Plus',
    logoPath: 'assets/logos/chatgpt.svg',
    cancellationUrl: 'https://www.chatgpt.com/',
    cancellationText: 'Te llevamos directamente al área de cliente de ChatGPT Plus.',
    cancellationInstructions: 'Perfil → Ajustes → Mi plan → Gestionar suscripción → Cancelar plan en el portal de Stripe.',
  ),
  TopService(
    id: 'claude_pro',
    name: 'Claude Pro',
    logoPath: 'assets/logos/claudepro.svg',
    cancellationUrl: 'https://www.claude.ai/settings/billing',
    cancellationText: 'Accede a la sección de suscripción de tu cuenta de Claude Pro.',
    cancellationInstructions: 'Avatar de usuario → Billing → Manage Subscription → Cancel Plan (efectivo al fin de ciclo).',
  ),
];
