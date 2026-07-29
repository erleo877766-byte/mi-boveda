enum OrderSourceDescription {
  unknown, order;

  String get title => name;

  static OrderSourceDescription fromRaw(int raw) =>
      OrderSourceDescription.values[raw];
}
