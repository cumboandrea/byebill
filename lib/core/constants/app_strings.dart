class AppStrings {
  AppStrings._();

  static String _currentLang = 'es';
  
  static void setLanguage(String lang) {
    _currentLang = lang;
  }

  /// Idioma activo ('es', 'en', 'it') — útil para decidir qué versión abrir.
  static String get currentLanguage => _currentLang;

  static String t(String es, String en, String it) {
    switch (_currentLang) {
      case 'en': return en;
      case 'it': return it;
      default: return es;
    }
  }

  static String get appName => 'ByeBill';
  
  static String get onboardingTitle => t(
    'Nunca más pagues\npor algo que querías\ncancelar',
    'Never pay again\nfor something you wanted\nto cancel',
    'Non pagare mai più\nper qualcosa che volevi\ncancellare'
  );
  
  static String get onboardingClaim => t(
    'ByeBill te ayuda a controlar tus suscripciones,',
    'ByeBill helps you track your subscriptions,',
    'ByeBill ti aiuta a controllare i tuoi abbonamenti,'
  );
  
  static String get onboardingSubtitle => t(
    'recordarte antes del cobro y cancelar\nen un clic.',
    'remind you before billing and cancel\nin one click.',
    'ricordarti prima dell\'addebito e cancellare\nin un clic.'
  );
  
  static String get onboardingCta => t('Empezar', 'Get Started', 'Inizia');
  
  static String get homeSavedTitle => t('Te has ahorrado:', 'You have saved:', 'Hai risparmiato:');
  
  static String get homeGreeting => t('Hola', 'Hello', 'Ciao');
  static String get homeExpiringSubtitle => t(
    'Tienes pruebas a punto de renovarse esta semana. ¡Evita cobros fantasma!',
    'You have trials renewing this week. Avoid ghost charges!',
    'Hai prove in scadenza questa settimana. Evita addebiti fantasma!'
  );
  static String get homeAttentionRequired => t('Atención requerida', 'Attention required', 'Attenzione richiesta');
  static String homeTrialsCount(int count) => t('$count pruebas', '$count trials', '$count prove');
  
  static String get homeActiveSubs => t('Suscripciones activas', 'Active subscriptions', 'Abbonamenti attivi');
  
  static String get homeEmptyTitle => t('Registra tu primera suscripción', 'Add your first subscription', 'Registra il tuo primo abbonamento');
  
  static String get homeEmptySubtitle => t(
    'Registra una prueba gratuita o suscripción\npara empezar a ahorrar.',
    'Add a free trial or subscription\nto start saving.',
    'Aggiungi una prova gratuita o un abbonamento\nper iniziare a risparmiare.'
  );

  static String get historyTitle => t('Histórico', 'History', 'Storico');
  static String get historySearchHint => t('Buscar servicio...', 'Search service...', 'Cerca servizio...');
  static String get historyFilterAll => t('Todos', 'All', 'Tutti');
  static String get historyFilterTrials => t('Pruebas agotadas', 'Expired trials', 'Prove scadute');
  static String get historyFilterCancelled => t('Canceladas', 'Cancelled', 'Cancellati');
  static String get historyEmptyTitle => t('Sin historial', 'No history', 'Nessuno storico');
  static String get historyEmptySubtitle => t(
    'Tus suscripciones canceladas\ny pruebas agotadas aparecerán aquí.',
    'Your cancelled subscriptions\nand expired trials will appear here.',
    'I tuoi abbonamenti cancellati\ne prove scadute appariranno qui.'
  );
  
  static String get savingsTitle => t('Ahorro', 'Savings', 'Risparmio');
  static String get savingsMonthlySpend => t('Gasto mensual activo', 'Active monthly spend', 'Spesa mensile attiva');
  static String get savingsSpendEvolutionTitle => t('Evolución del Gasto', 'Spend Evolution', 'Evoluzione della Spesa');
  static String get savingsSpendEvolutionEmpty => t(
    'El gráfico de evolución aparecerá cuando tengas gastos registrados en meses anteriores.', 
    'The evolution chart will appear when you have spending recorded in previous months.', 
    'Il grafico di evoluzione apparirà quando avrai spese registrate nei mesi precedenti.'
  );
  static String get savingsThisMonth => t('Este mes', 'This month', 'Questo mese');
  static String get savingsThisYear => t('Este año', 'This year', 'Quest\'anno');
  static String get savingsTotal => t('Total ahorrado', 'Total saved', 'Totale risparmiato');
  static String get savingsTopServices => t('Tus mayores ahorros', 'Top savings', 'I tuoi maggiori risparmi');
  static String get savingsEquivalenceTitle => t('¿A qué equivale?', 'What does this mean?', 'A cosa equivale?');
  
  static String get savingsEqCoffee => t('Unos buenos cafés', 'A few good coffees', 'Qualche buon caffè');
  static String get savingsEqCinema => t('Dos entradas de cine', 'Two cinema tickets', 'Due biglietti del cinema');
  static String get savingsEqDinner => t('Una cena fuera', 'A nice dinner out', 'Una cena fuori');
  static String get savingsEqFlight => t('Un vuelo de fin de semana', 'A weekend flight', 'Un volo per il weekend');
  static String get savingsEqGadget => t('Un buen gadget tecnológico', 'A cool tech gadget', 'Un bel gadget tecnologico');
  
  static String get savingsEmptyTitle => t('Aún no hay ahorros', 'No savings yet', 'Nessun risparmio ancora');
  static String get savingsEmptySubtitle => t(
    'Cuando canceles suscripciones\no pruebas, verás aquí el dinero\nque has evitado gastar.',
    'When you cancel subscriptions\nor trials, you will see here the money\nyou have avoided spending.',
    'Quando cancelli abbonamenti\no prove, vedrai qui i soldi\nche hai evitato di spendere.'
  );

  static String get addTitle => t('Añadir suscripción', 'Add subscription', 'Aggiungi abbonamento');
  static String get editTitle => t('Editar suscripción', 'Edit subscription', 'Modifica abbonamento');
  
  static String get addServiceLabel => t('Servicio', 'Service', 'Servizio');
  static String get addServiceHint => t('Ej. Almacenamiento en la nube', 'E.g. Cloud storage', 'Es. Archiviazione cloud');
  
  static String get addAmountLabel => t('Importe', 'Amount', 'Importo');
  static String get addAmountHint => '0,00 €';
  
  static String get addDateLabel => t('Fecha de cobro', 'Billing date', 'Data di addebito');
  static String get addDateHint => t('Selecciona una fecha', 'Select a date', 'Seleziona una data');

  static String get addStartDateLabel => t('¿Desde cuándo pagas esto?', 'Since when do you pay for this?', 'Da quando paghi per questo?');
  static String get addStartDateHint => t('Opcional · permite calcular tu historial', 'Optional · used to build your history', 'Opzionale · usato per costruire il tuo storico');
  
  static String get addTypeTrial => t('Prueba gratuita', 'Free trial', 'Prova gratuita');
  static String get addTypeSubscription => t('Suscripción', 'Subscription', 'Abbonamento');
  
  static String get addSaveCta => t('Guardar suscripción', 'Save subscription', 'Salva abbonamento');
  
  static String get detailTitle => t('Detalle suscripción', 'Subscription details', 'Dettagli abbonamento');
  static String get detailCancelCta => t('Marcar como cancelada', 'Mark as cancelled', 'Segna come cancellato');
  static String get detailEditCta => t('Editar', 'Edit', 'Modifica');
  static String get detailDeleteCta => t('Eliminar suscripción', 'Delete subscription', 'Elimina abbonamento');
  
  static String get detailNextAlerts => t('Próximas alertas', 'Next alerts', 'Prossimi avvisi');
  
  static String get detailStatusActive => t('Activa', 'Active', 'Attivo');
  static String get detailStatusCancelled => t('Cancelada', 'Cancelled', 'Cancellato');
  
  static String get cycleMonthly => t('Mensual', 'Monthly', 'Mensile');
  static String get cycleAnnual => t('Anual', 'Annual', 'Annuale');
  
  static String get detailDeleteConfirm => t(
    '¿Estás seguro de eliminar esta suscripción?\nDesaparecerá completamente de la base de datos y no se mostrará en el Histórico.',
    'Are you sure you want to delete this subscription?\nIt will be completely removed from the database and won\'t appear in History.',
    'Sei sicuro di voler eliminare questo abbonamento?\nVerrà rimosso completamente dal database e non apparirà nello Storico.'
  );
  static String get detailDeleteConfirmCta => t('Eliminar', 'Delete', 'Elimina');
  
  static String get detailCancelConfirm => t(
    '¿Confirmas que has cancelado esta suscripción?\nDejarás de recibir alertas.',
    'Do you confirm you have cancelled this subscription?\nYou will stop receiving alerts.',
    'Confermi di aver cancellato questo abbonamento?\nSmetterai di ricevere avvisi.'
  );
  static String get detailCancelConfirmCta => t('Confirmar cancelación', 'Confirm cancellation', 'Conferma cancellazione');
  
  static String get tileExpired => t('Caducada', 'Expired', 'Scaduta');
  static String tileDaysLeft(int days) => t('Quedan $days días', '$days days left', 'Mancano $days giorni');
  static String tileDays(int days) => t('$days días', '$days days', '$days giorni');
  static String tileTrialEnded(String date, String price) => t('Prueba terminada el $date · $price/mes', 'Trial ended on $date · $price/mo', 'Prova terminata il $date · $price/mese');
  static String tileTrialEnds(String date, String price) => t('Prueba termina el $date · $price/mes', 'Trial ends on $date · $price/mo', 'Prova termina il $date · $price/mese');
  static String tileNextCharge(String date, String price) => t('Próximo cobro: $date · $price/mes', 'Next charge: $date · $price/mo', 'Prossimo addebito: $date · $price/mese');

  static String get snackbarSaved => t('Suscripción guardada', 'Subscription saved', 'Abbonamento salvato');
  static String get snackbarCancelled => t('¡Suscripción cancelada! Ahorro registrado', 'Subscription cancelled! Savings recorded', 'Abbonamento cancellato! Risparmio registrato');
  static String get snackbarDeleted => t('Suscripción eliminada', 'Subscription deleted', 'Abbonamento eliminato');
  static String get snackbarUpdated => t('Suscripción actualizada', 'Subscription updated', 'Abbonamento aggiornato');
  
  static String get snackbarPermissionDenied => t(
    'Activa las notificaciones en Ajustes para no perder alertas',
    'Enable notifications in Settings to not miss alerts',
    'Attiva le notifiche nelle Impostazioni per non perdere gli avvisi'
  );
  static String get snackbarPermissionDeniedCta => t('Abrir ajustes', 'Open settings', 'Apri impostazioni');
  
  static String badgeDays(int days) {
    if (days < 0) return t('Vencido', 'Expired', 'Scaduto');
    if (days == 0) return t('Hoy', 'Today', 'Oggi');
    if (days == 1) return t('Falta $days día', '$days day left', 'Manca $days giorno');
    return t('Faltan $days días', '$days days left', 'Mancano $days giorni');
  }

  static String get premiumLockedTime => t('Exclusivo Premium', 'Premium only', 'Solo Premium');
  static String get premiumLimitTitle => t('Límite alcanzado', 'Limit reached', 'Limite raggiunto');
  static String get premiumLimitMsg => t(
    'Hazte Premium para añadir suscripciones ilimitadas.', 
    'Go Premium to add unlimited subscriptions.', 
    'Passa a Premium per aggiungere abbonamenti illimitati.'
  );
  static String get premiumUpgradeBtn => t('Ver Premium', 'See Premium', 'Vedi Premium');

  // Ventajas Premium
  static String get premiumBenefitAdFreeTitle => t('Sin publicidad', 'Ad-free experience', 'Nessuna pubblicità');
  static String get premiumBenefitAdFreeDesc => t(
    'Disfruta de la aplicación sin anuncios molestos ni interrupciones.', 
    'Enjoy the app without annoying ads or interruptions.', 
    'Goditi l\'app senza fastidiosi annunci o interruzioni.'
  );

  // Planes de precio
  static String get premiumPlanMonthly => t('Mensual', 'Monthly', 'Mensile');
  static String premiumPlanMonthlyPrice(String c) => t('2,99 $c/mes', '2.99 $c/mo', '2,99 $c/mese');
  
  static String get premiumPlanAnnual => t('Anual', 'Annual', 'Annuale');
  static String premiumPlanAnnualPrice(String c) => t('19,99 $c/año', '19.99 $c/yr', '19,99 $c/anno');
  static String premiumPlanAnnualDesc(String c) => t('sale a 1,67 $c/mes', 'only 1.67 $c/mo', 'solo 1,67 $c/mese');
  
  static String get premiumPlanLifetime => t('De por vida', 'Lifetime', 'A vita');
  static String premiumPlanLifetimePrice(String c) => t('34,99 $c', '34.99 $c', '34,99 $c');
  static String get premiumPlanLifetimeDesc => t('pago único', 'one-time payment', 'pagamento unico');
  static String get premiumMostPopular => t('MÁS POPULAR', 'MOST POPULAR', 'PIÙ POPOLARE');

  // Alertas
  static String get alertsTitle => t('Centro de Alertas', 'Alert Center', 'Centro Avvisi');
  static String get alertsEmpty => t('Todo tranquilo por aquí.', 'All quiet here.', 'Tutto tranquillo qui.');
  static String get alertsTrialTitle => t('Prueba a punto de caducar', 'Trial expiring soon', 'Prova in scadenza');
  static String alertsTrialExpiring(String name, int days) => t('$name caduca en $days días', '$name expires in $days days', '$name scade in $days giorni');
  static String get alertsChargeTitle => t('Próximo cobro', 'Upcoming charge', 'Prossimo addebito');
  static String alertsChargeSoon(String name, int days) => t('Cobro de $name en $days días', 'Charge for $name in $days days', 'Addebito per $name in $days giorni');
  static String get alertsSavingsTitle => t('¡Buen trabajo!', 'Great job!', 'Ottimo lavoro!');
  static String alertsSavings(String amount) => t('Has ahorrado $amount este mes.', 'You saved $amount this month.', 'Hai risparmiato $amount questo mese.');
  static String get alertsPremiumTitle => t('Mejora tus notificaciones', 'Upgrade notifications', 'Migliora le notifiche');
  static String get alertsPremiumUpsell => t('Pásate a Premium para alertas con 7 días de antelación.', 'Go Premium for 7-day advance alerts.', 'Passa a Premium per avvisi con 7 giorni di anticipo.');

  static String get generalError => t('Ha ocurrido un error, inténtalo de nuevo', 'An error occurred, please try again', 'Si è verificato un errore, riprova');
}
