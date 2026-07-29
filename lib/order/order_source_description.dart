enum OrderSourceDescription {
  unknown;

  String get title => name;

  static OrderSourceDescription fromRaw(int raw) =>
      OrderSourceDescription.values[raw];
}
