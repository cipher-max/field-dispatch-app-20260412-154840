import 'package:uuid/uuid.dart';

import '../../core/config/app_env.dart';
import '../../shared/models/invoice.dart';

class StripePaymentLinkService {
  static const _uuid = Uuid();

  String? buildPaymentLink(Invoice invoice) {
    final base = AppEnv.stripePaymentLinkBaseUrl;
    if (base.isEmpty) return null;

    final uri = Uri.tryParse(base);
    if (uri == null) return null;

    final nextQuery = {
      ...uri.queryParameters,
      'invoice_id': invoice.id,
      'job_id': invoice.jobId,
      'customer': invoice.customerName,
      'amount_cents': invoice.amountDueCents.toString(),
      'currency': 'usd',
      'reference': _uuid.v4(),
    };

    return uri.replace(queryParameters: nextQuery).toString();
  }
}
