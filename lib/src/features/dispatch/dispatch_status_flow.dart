import '../jobs/domain/job_status.dart';

JobStatus? nextDispatchStatus(JobStatus current) {
  switch (current) {
    case JobStatus.newJob:
      return JobStatus.scheduled;
    case JobStatus.scheduled:
      return JobStatus.inProgress;
    case JobStatus.inProgress:
      return JobStatus.done;
    case JobStatus.done:
      return null;
  }
}
