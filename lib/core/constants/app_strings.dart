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
  static String get onboardingSkip => t('Omitir', 'Skip', 'Salta');
  static String get onboardingNext => t('Continuar', 'Continue', 'Continua');

  static String get onboardingSlide2Title => t('Avisos antes de cada cobro', 'Alerts before payment', 'Avvisi prima di ogni addebito');
  static String get onboardingSlide2Subtitle => t(
    'Te avisamos con antelación para que decidas tú: renovar o cancelar.',
    'We alert you in advance so you decide: renew or cancel.',
    'Ti avvisiamo in anticipo così decidi tu: rinnovare o cancellare.'
  );

  static String get onboardingSlide3Title => t('Descubre cuánto ahorras', 'See how much you save', 'Scopri quanto risparmi');
  static String get onboardingSlide3Subtitle => t(
    'Cancela en un clic y mira mes a mes todo lo que te estás ahorrando.',
    'Cancel in one click and track month by month everything you save.',
    'Cancella in un clic e guarda mese per mese tutto quello che risparmi.'
  );
  
  static String get homeSavedTitle => t('Te has ahorrado:', 'You have saved:', 'Hai risparmiato:');
  
  static String get homeGreeting => t('Hola', 'Hello', 'Ciao');
  static String get homeExpiringSubtitle => t(
    'Tienes cobros o pruebas pendientes esta semana. ¡Evita sustos!',
    'You have charges or trials due this week. Avoid surprises!',
    'Hai addebiti o prove in scadenza questa settimana. Evita sorprese!'
  );
  static String get homeAttentionRequired => t('Atención requerida', 'Attention required', 'Attenzione richiesta');
  static String homeExpiringCount(int count) => t('$count avisos', '$count alerts', '$count avvisi');
  
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
  static String get savingsSpentThisYear => t('Gastado este año', 'Spent this year', 'Speso quest\'anno');
  static String savingsCancelledOn(String date) => t('Cancelado el $date', 'Cancelled on $date', 'Cancellato il $date');
  static String savingsPerMonth(String amount) => t('($amount / mes)', '($amount / month)', '($amount / mese)');
  static String savingsPerYear(String amount) => t('($amount / año)', '($amount / year)', '($amount / anno)');
  static String get savingsSpendEmpty => t('Sin gasto todavía este año', 'No spending yet this year', 'Nessuna spesa ancora quest\'anno');
  static String get savingsSpendEvolutionTitle => t('Evolución del Gasto', 'Spend Evolution', 'Evoluzione della Spesa');
  static String get savingsSpendEvolutionEmpty => t(
    'El gráfico de evolución aparecerá cuando tengas gastos registrados en meses anteriores.', 
    'The evolution chart will appear when you have spending recorded in previous months.', 
    'Il grafico di evoluzione apparirà quando avrai spese registrate nei mesi precedenti.'
  );
  static String get savingsThisMonth => t('Este mes', 'This month', 'Questo mese');
  static String get savingsThisYear => t('Este año', 'This year', 'Quest\'anno');
  static String get savingsBreakdownTitle => t('Desglose por servicio', 'By service', 'Dettaglio per servizio');
  static String get savingsBreakdownEmpty => t('Sin ahorros todavía en este periodo', 'No savings yet in this period', 'Nessun risparmio ancora in questo periodo');
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
  static String get detailCancelCta => t('Dejar de pagar', 'Stop paying', 'Smetti di pagare');
  static String get detailEditCta => t('Editar', 'Edit', 'Modifica');
  static String get detailDeleteCta => t('Eliminar suscripción', 'Delete subscription', 'Elimina abbonamento');
  
  static String get detailNextAlerts => t('Próximas alertas', 'Next alerts', 'Prossimi avvisi');
  
  static String get detailStatusActive => t('Activa', 'Active', 'Attivo');
  static String get detailStatusCancelled => t('Cancelada', 'Cancelled', 'Cancellato');
  
  static String get cycleMonthly => t('Mensual', 'Monthly', 'Mensile');
  static String get cycleAnnual => t('Anual', 'Annual', 'Annuale');
  static String get freeTrialBadge => t('Gratuita', 'Free', 'Gratuita');
  
  static String get detailDeleteConfirm => t(
    '¿Estás seguro de eliminar esta suscripción?\nDesaparecerá completamente de la base de datos y no se mostrará en el Histórico.',
    'Are you sure you want to delete this subscription?\nIt will be completely removed from the database and won\'t appear in History.',
    'Sei sicuro di voler eliminare questo abbonamento?\nVerrà rimosso completamente dal database e non apparirà nello Storico.'
  );
  static String get detailDeleteConfirmCta => t('Eliminar', 'Delete', 'Elimina');
  static String get detailDeleteHint => t(
    'Esta suscripción se eliminará por completo y no se tendrá en cuenta en los cálculos de Ahorro.',
    'This subscription will be permanently removed and won\'t be taken into account in Savings calculations.',
    'Questo abbonamento verrà eliminato completamente e non sarà considerato nei calcoli del Risparmio.'
  );
  
  static String get detailCancelConfirm => t(
    '¿Confirmas que has dejado de pagar esta suscripción?\nSi la dejaste de pagar hace unos días, indica la fecha exacta para que el Ahorro no cuente cobros que no se produjeron.',
    'Do you confirm you have stopped paying for this subscription?\nIf you stopped paying a few days ago, set the exact date so Savings doesn\'t count charges that never happened.',
    'Confermi che hai smesso di pagare questo abbonamento?\nSe hai smesso di pagare qualche giorno fa, indica la data esatta così il Risparmio non conta addebiti mai avvenuti.'
  );
  static String get detailCancelConfirmCta => t('Sí, dejar de pagar', 'Yes, stop paying', 'Sì, smetti di pagare');
  static String get cancelSinceLabel => t(
    'Dejé de pagar el',
    'I stopped paying on',
    'Ho smesso di pagare il'
  );
  static String get cancelChangeDate => t(
    'Cambiar fecha',
    'Change date',
    'Cambia data'
  );
  static String get cancelFutureDateHint => t(
    'No puede ser una fecha futura',
    'It cannot be a future date',
    'Non può essere una data futura'
  );
  
  static String get tileExpired => t('Caducada', 'Expired', 'Scaduta');
  static String tileDaysLeft(int days) => t('Quedan $days días', '$days days left', 'Mancano $days giorni');
  static String tileDays(int days) => t('$days días', '$days days', '$days giorni');
  static String tileTrialEnded(String date, String price) => t('Prueba terminada el $date · $price/mes', 'Trial ended on $date · $price/mo', 'Prova terminata il $date · $price/mese');
  static String tileTrialEnds(String date, String price) => t('Prueba termina el $date · $price/mes', 'Trial ends on $date · $price/mo', 'Prova termina il $date · $price/mese');
  static String tileNextCharge(String date, String price) => t('Próximo cobro: $date · $price/mes', 'Next charge: $date · $price/mo', 'Prossimo addebito: $date · $price/mese');

  static String get snackbarSaved => t('Suscripción guardada', 'Subscription saved', 'Abbonamento salvato');
  static String get snackbarCancelled => t('Dejaste de pagar. ¡Ahorro registrado!', 'You stopped paying. Savings recorded!', 'Hai smesso di pagare. Risparmio registrato!');
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

  // Perfil
  static String get profileTitle => t('Perfil', 'Profile', 'Profilo');
  static String get profilePremiumStatus => t('Estado del plan', 'Plan status', 'Stato del piano');
  static String get profilePremiumActive => t('Premium activo', 'Premium active', 'Premium attivo');
  static String get profileFree => t('Plan gratuito', 'Free plan', 'Piano gratuito');
  static String get profileUpgradeCta => t('Hazte Premium', 'Go Premium', 'Passa a Premium');
  static String get profileUpgradeSubtitle => t('Sin anuncios y avisos con 7 días de antelación.', 'No ads and 7-day advance alerts.', 'Niente pubblicità e avvisi con 7 giorni di anticipo.');
  static String profilePlanExpires(String date) => t('Caduca el $date', 'Expires on $date', 'Scade il $date');
  static String get profilePlanNeverExpires => t('No caduca nunca', 'Never expires', 'Non scade mai');
  static String get profileCuriousData => t('Tu año en ByeBill', 'Your year in ByeBill', 'Il tuo anno in ByeBill');
  static String get profileTopSpends => t('Tus 3 suscripciones más caras', 'Your 3 most expensive subscriptions', 'I tuoi 3 abbonamenti più costosi');
  static String get profileSavedThisYear => t('Ahorrado este año', 'Saved this year', 'Risparmiato quest\'anno');
  static String get profileSavedAllTime => t('Ahorrado en total', 'Saved in total', 'Risparmiato in totale');
  static String get profileNoData => t('Aún no hay datos.', 'No data yet.', 'Ancora nessun dato.');

  // Alertas
  static String get alertsTitle => t('Centro de Alertas', 'Alert Center', 'Centro Avvisi');
  static String get alertsEmpty => t('Todo tranquilo por aquí.', 'All quiet here.', 'Tutto tranquillo qui.');
  static String get alertsTrialTitle => t('Prueba a punto de caducar', 'Trial expiring soon', 'Prova in scadenza');
  static String alertsTrialExpiring(String name, int days) => t('$name caduca en $days días', '$name expires in $days days', '$name scade in $days giorni');
  static String get alertsChargeTitle => t('Próximo cobro', 'Upcoming charge', 'Prossimo addebito');
  static String alertsChargeSoon(String name, int days) => t('Cobro de $name en $days días', 'Charge for $name in $days days', 'Addebito per $name in $days giorni');
  static String get alertsSavingsTitle => t('¡Buen trabajo!', 'Great job!', 'Ottimo lavoro!');
  static String alertsSavings(String amount) => t('Has ahorrado $amount este mes.', 'You saved $amount this month.', 'Hai risparmiato $amount questo mese.');
  static String get alertsRenewedTitle => t('Renovación automática', 'Auto-renewed', 'Rinnovo automatico');
  static String alertsRenewed(String name, String date) => t('$name se ha renovado automáticamente el $date', '$name auto-renewed on $date', '$name si è rinnovato automaticamente il $date');
  static String get alertsPremiumTitle => t('Mejora tus notificaciones', 'Upgrade notifications', 'Migliora le notifiche');
  static String get alertsPremiumUpsell => t('Pásate a Premium para alertas con 7 días de antelación.', 'Go Premium for 7-day advance alerts.', 'Passa a Premium per avvisi con 7 giorni di anticipo.');

  static String get generalError => t('Ha ocurrido un error, inténtalo de nuevo', 'An error occurred, please try again', 'Si è verificato un errore, riprova');
}
