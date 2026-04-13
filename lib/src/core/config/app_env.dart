class AppEnv {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  // Optional. If set, invoices can generate customer payment links without
  // hardcoding Stripe keys in the app.
  static const stripePaymentLinkBaseUrl = String.fromEnvironment(
    'STRIPE_PAYMENT_LINK_BASE_URL',
    defaultValue: '',
  );

  // Optional. Store these only in backend/server flows, never directly in app
  // binaries for production.
  static const stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  static const quickbooksClientId = String.fromEnvironment(
    'QUICKBOOKS_CLIENT_ID',
    defaultValue: '',
  );

  static bool get hasStripeLinkBase => stripePaymentLinkBaseUrl.isNotEmpty;
  static bool get hasQuickBooksClientId => quickbooksClientId.isNotEmpty;
}
