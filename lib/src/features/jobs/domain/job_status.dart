enum JobStatus { newJob, scheduled, inProgress, done }

extension JobStatusX on JobStatus {
  String get value {
    switch (this) {
      case JobStatus.newJob:
        return 'new';
      case JobStatus.scheduled:
        return 'scheduled';
      case JobStatus.inProgress:
        return 'in_progress';
      case JobStatus.done:
        return 'done';
    }
  }

  String get label {
    switch (this) {
      case JobStatus.newJob:
        return 'New';
      case JobStatus.scheduled:
        return 'Scheduled';
      case JobStatus.inProgress:
        return 'In Progress';
      case JobStatus.done:
        return 'Done';
    }
  }

  static JobStatus fromValue(String raw) {
    return JobStatus.values.firstWhere(
      (s) => s.value == raw,
      orElse: () => JobStatus.newJob,
    );
  }
}
