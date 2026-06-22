const addressStr = '{"fullName":"John","phone":"123","flatHouse":"","street":"Main","landmark":"","city":"","state":"","zipCode":""}';
const parsed = JSON.parse(addressStr);
console.log(parsed.flatHouse || '');
console.log(parsed.city || '');
