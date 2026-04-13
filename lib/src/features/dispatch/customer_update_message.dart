import '../../shared/models/job.dart';

enum DispatchMessageTemplate { scheduled, onTheWay, delayed, completed }

String buildCustomerUpdateMessage(Job job) {
  final tech = job.technicianName?.trim();
  final eta = job.etaWindow?.trim();

  final techPart = (tech == null || tech.isEmpty) ? 'our technician' : tech;
  final hasEta = eta != null && eta.isNotEmpty;

  switch (job.status) {
    case 'in_progress':
      final etaPart = hasEta ? ' and should arrive by $eta' : '';
      return 'Hi ${job.customerName}, $techPart is on the way for your ${job.jobType}$etaPart.';
    case 'done':
      return 'Hi ${job.customerName}, $techPart has completed your ${job.jobType}. Reply here if you need anything else.';
    default:
      if (hasEta) {
        return 'Hi ${job.customerName}, $techPart is scheduled for your ${job.jobType} at $eta. We will text again if anything changes.';
      }

      return 'Hi ${job.customerName}, $techPart is scheduled for your ${job.jobType} today. We will text again if anything changes.';
  }
}

String buildCustomerUpdateTemplateMessage(
  Job job,
  DispatchMessageTemplate template,
) {
  final tech = job.technicianName?.trim();
  final eta = job.etaWindow?.trim();
  final techPart = (tech == null || tech.isEmpty) ? 'our technician' : tech;
  final etaPart = (eta == null || eta.isEmpty) ? '' : ' ETA: $eta.';

  switch (template) {
    case DispatchMessageTemplate.scheduled:
      return 'Hi ${job.customerName}, your ${job.jobType} visit is scheduled with $techPart.$etaPart We will text if anything changes.';
    case DispatchMessageTemplate.onTheWay:
      return 'Hi ${job.customerName}, $techPart is on the way for your ${job.jobType}.$etaPart';
    case DispatchMessageTemplate.delayed:
      return 'Hi ${job.customerName}, quick update: we are running behind for your ${job.jobType}. New$etaPart Thanks for your patience.';
    case DispatchMessageTemplate.completed:
      return 'Hi ${job.customerName}, your ${job.jobType} has been completed. Reply if you need anything else.';
  }
}
