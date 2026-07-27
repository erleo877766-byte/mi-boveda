enum OrderSourceDescription {
  unknown;

  static OrderSourceDescription fromRaw(int raw) =>
      OrderSourceDescription.values[raw];
}
