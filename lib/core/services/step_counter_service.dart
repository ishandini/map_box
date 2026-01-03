class StepCounterService {
  static int _currentSteps = 0;

  static int getUserStepCount() {
    return _currentSteps;
  }

  static void setUserStepCount(int steps) {
    _currentSteps = steps;
  }

  static void incrementSteps(int amount) {
    _currentSteps += amount;
  }
}
