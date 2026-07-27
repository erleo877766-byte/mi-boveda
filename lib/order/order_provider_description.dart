enum OrderProviderDescription {
  cakePay;

  static OrderProviderDescription fromRaw(int raw) =>
      OrderProviderDescription.values[raw];
}
