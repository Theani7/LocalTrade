const address = '{"fullName":"John","phone":"123","flatHouse":"","street":"Main","landmark":"","city":"","state":"","zipCode":""}';
const parsed = typeof address === 'string' ? JSON.parse(address) : address;
if (typeof parsed === 'object' && parsed !== null) {
  const updateData = {};
  updateData.address = {
    fullName: parsed.fullName || '',
    phone: parsed.phone || '',
    flatHouse: parsed.flatHouse || '',
    street: parsed.street || '',
    landmark: parsed.landmark || '',
    city: parsed.city || '',
    state: parsed.state || '',
    zipCode: parsed.zipCode || '',
  };
  console.log(updateData);
}
