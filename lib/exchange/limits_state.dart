abstract class LimitsState {
  const LimitsState();
}

class LimitsInitialState extends LimitsState {
  const LimitsInitialState();
}

class LimitsLoaded extends LimitsState {
  final double min;
  final double max;
  const LimitsLoaded({required this.min, required this.max});
}

class LimitsError extends LimitsState {
  final String error;
  const LimitsError(this.error);
}

class LimitsLoading extends LimitsState {
  const LimitsLoading();
}

typedef LimitsIsLoading = LimitsLoading;
