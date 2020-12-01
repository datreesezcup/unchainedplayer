

extension DurationExtensions on Duration {

  String get runtimeString {
    if(this.inDays > 0){ throw UnsupportedError("You shouldn't be using 'runtimeString' for periods longer than a day'"); }
    int totalSeconds = this.inSeconds;
    int minutes = (totalSeconds / 60).floor();
    int remainingSeconds = totalSeconds % 60;
    return "$minutes:${remainingSeconds.toString().padLeft(2, "0")}";


  }
}