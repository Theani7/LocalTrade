require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('./src/models/userModel');
const Product = require('./src/models/productModel');

const seedData = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    console.log('Cleaning old mock data...');
    // Only delete mock users, keep the admin if it exists
    await User.deleteMany({ email: { $in: [
      'farm@example.com', 'crafts@example.com', 'dairy@example.com', 'clothing@example.com',
      'spices@example.com', 'tea@example.com', 'sweets@example.com', 'bakery@example.com',
      'localgoods@example.com', 'pottery@example.com'
    ]}});
    // For products, we can clear all to start fresh for the 50 count
    await Product.deleteMany({});

    console.log('Creating 10 Local Vendors...');
    const password = await bcrypt.hash('password123', 12);

    const vendorsData = [
      { fullName: 'Mustang Agro Center', email: 'farm@example.com', phone: '9841000001', password, address: 'Marpha, Mustang', role: 'vendor', vendorApprovalStatus: 'approved' },
      { fullName: 'Patan Artisan Guild', email: 'crafts@example.com', phone: '9841000002', password, address: 'Mangal Bazaar, Patan', role: 'vendor', vendorApprovalStatus: 'approved' },
      { fullName: 'Kanchanjunga Tea Estate', email: 'tea@example.com', phone: '9841000005', password, address: 'Ilam, Nepal', role: 'vendor', vendorApprovalStatus: 'approved' },
      { fullName: 'Gundruk & Spices House', email: 'spices@example.com', phone: '9841000006', password, address: 'Asan, Kathmandu', role: 'vendor', vendorApprovalStatus: 'approved' },
      { fullName: 'Kathmandu Mithai Bhandar', email: 'sweets@example.com', phone: '9841000007', password, address: 'Indra Chowk, Kathmandu', role: 'vendor', vendorApprovalStatus: 'approved' },
      { fullName: 'Bhaktapur Pottery Works', email: 'pottery@example.com', phone: '9841000008', password, address: 'Pottery Square, Bhaktapur', role: 'vendor', vendorApprovalStatus: 'approved' },
      { fullName: 'Langtang Cheese Hub', email: 'dairy@example.com', phone: '9841000003', password, address: 'Langtang Valley', role: 'vendor', vendorApprovalStatus: 'approved' },
      { fullName: 'Palpali Dhaka Sadan', email: 'clothing@example.com', phone: '9841000004', password, address: 'Tansen, Palpa', role: 'vendor', vendorApprovalStatus: 'approved' },
      { fullName: 'Jumla Organic Depot', email: 'localgoods@example.com', phone: '9841000009', password, address: 'Jumla Bazaar', role: 'vendor', vendorApprovalStatus: 'approved' },
      { fullName: 'Himalayan Woolens', email: 'bakery@example.com', phone: '9841000010', password, address: 'Thamel, Kathmandu', role: 'vendor', vendorApprovalStatus: 'approved' }
    ];

    const createdVendors = await User.insertMany(vendorsData);
    const v = createdVendors; // Alias for convenience

    console.log('Creating 50+ Local Nepali Products...');

    const products = [
      // --- MUSTANG AGRO (Mustang Apples, Apricots) ---
      { title: 'Organic Mustang Dried Apples', description: 'Crispy and sweet dried apple slices from the orchards of Marpha.', category: 'Local Goods', price: 450, stock: 100, vendorId: v[0]._id, vendorName: v[0].fullName, location: v[0].address, images: ['https://images.unsplash.com/photo-1567306226416-28f0efdc88ce'] },
      { title: 'Mustang Apple Brandy (Local)', description: 'Famous Marpha brandy distilled from organic apples.', category: 'Local Goods', price: 1200, stock: 40, vendorId: v[0]._id, vendorName: v[0].fullName, location: v[0].address, images: ['https://images.unsplash.com/photo-1516535794938-6063878f08cc'] },
      { title: 'Dried Apricots (Jardalu)', description: 'Sun-dried sweet apricots from Mustang.', category: 'Local Goods', price: 600, stock: 60, vendorId: v[0]._id, vendorName: v[0].fullName, location: v[0].address, images: ['https://images.unsplash.com/photo-1596591606975-97ee5cef3a1e'] },
      { title: 'Buckwheat Flour (Phapar)', description: 'Nutritious buckwheat flour, gluten-free and organic.', category: 'Local Goods', price: 180, stock: 200, vendorId: v[0]._id, vendorName: v[0].fullName, location: v[0].address, images: ['https://images.unsplash.com/photo-1509440159596-0249088772ff'] },
      { title: 'Jimbu (Himalayan Herb)', description: 'Unique aromatic herb used in Nepali lentils (Dal).', category: 'Local Goods', price: 150, stock: 300, vendorId: v[0]._id, vendorName: v[0].fullName, location: v[0].address, images: ['https://images.unsplash.com/photo-1509358271058-acd22cc93898'] },

      // --- PATAN ARTISANS (Metal & Crafts) ---
      { title: 'Copper Pooja Thali Set', description: 'Traditional hand-beaten copper plate set for rituals.', category: 'Handicrafts', price: 2800, stock: 15, vendorId: v[1]._id, vendorName: v[1].fullName, location: v[1].address, images: ['https://images.unsplash.com/photo-1614362143314-490332846f4a'] },
      { title: 'Brass Karuwa (Water Vessel)', description: 'Classic Newari brass vessel with intricate carvings.', category: 'Handicrafts', price: 3500, stock: 10, vendorId: v[1]._id, vendorName: v[1].fullName, location: v[1].address, images: ['https://images.unsplash.com/photo-1584622650111-993a426fbf0a'] },
      { title: 'Incense Stick Holder (Lotus)', description: 'Bronze carved lotus flower incense holder.', category: 'Handicrafts', price: 850, stock: 45, vendorId: v[1]._id, vendorName: v[1].fullName, location: v[1].address, images: ['https://images.unsplash.com/photo-1602192103300-47e66756152e'] },
      { title: 'Handmade Lokta Paper Notebook', description: 'Durable notebook made from indigenous Lokta bark.', category: 'Handicrafts', price: 400, stock: 100, vendorId: v[1]._id, vendorName: v[1].fullName, location: v[1].address, images: ['https://images.unsplash.com/photo-1544816155-12df9643f363'] },
      { title: 'Statue of Green Tara (Bronze)', description: 'Small detailed bronze statue for home altars.', category: 'Handicrafts', price: 12500, stock: 3, vendorId: v[1]._id, vendorName: v[1].fullName, location: v[1].address, images: ['https://images.unsplash.com/photo-1544124499-58912cbddaad'] },

      // --- ILAM TEA (Tea & Coffee) ---
      { title: 'Ilam First Flush Tea', description: 'Premium quality golden tip black tea from Ilam.', category: 'Local Goods', price: 850, stock: 80, vendorId: v[2]._id, vendorName: v[2].fullName, location: v[2].address, images: ['https://images.unsplash.com/photo-1594631252845-59fc5973f7d8'] },
      { title: 'White Tea (Silver Needles)', description: 'Rare and delicate white tea buds, extremely healthy.', category: 'Local Goods', price: 1500, stock: 20, vendorId: v[2]._id, vendorName: v[2].fullName, location: v[2].address, images: ['https://images.unsplash.com/photo-1597481499750-3e6b21643242'] },
      { title: 'Organic Gulmi Coffee', description: 'Medium roast arabica beans from the hills of Gulmi.', category: 'Local Goods', price: 1100, stock: 50, vendorId: v[2]._id, vendorName: v[2].fullName, location: v[2].address, images: ['https://images.unsplash.com/photo-1559056199-641a0ac8b55e'] },
      { title: 'Lemongrass Herbal Tea', description: 'Refreshing dried lemongrass stalks for caffeine-free tea.', category: 'Local Goods', price: 350, stock: 120, vendorId: v[2]._id, vendorName: v[2].fullName, location: v[2].address, images: ['https://images.unsplash.com/photo-1564890369478-c89ca6d9cde9'] },
      { title: 'Masala Tea Blend', description: 'Authentic blend of CTC tea with ginger, cardamom, and clove.', category: 'Local Goods', price: 450, stock: 150, vendorId: v[2]._id, vendorName: v[2].fullName, location: v[2].address, images: ['https://images.unsplash.com/photo-1517686469429-8bdb88b9f907'] },

      // --- ASAN SPICES (Gundruk, Timur, Spices) ---
      { title: 'Fermented Spinach (Gundruk)', description: 'Traditional Nepali fermented leafy green, sun-dried.', category: 'Local Goods', price: 200, stock: 200, vendorId: v[3]._id, vendorName: v[3].fullName, location: v[3].address, images: ['https://images.unsplash.com/photo-1512621776951-a57141f2eefd'] },
      { title: 'Timur (Szechuan Pepper)', description: 'Aromatic and numbing wild pepper from Western Nepal.', category: 'Local Goods', price: 300, stock: 150, vendorId: v[3]._id, vendorName: v[3].fullName, location: v[3].address, images: ['https://images.unsplash.com/photo-1532336414038-cf1905044314'] },
      { title: 'Turmeric Powder (Besar)', description: 'Pure, bright yellow turmeric grown in the Terai.', category: 'Local Goods', price: 150, stock: 500, vendorId: v[3]._id, vendorName: v[3].fullName, location: v[3].address, images: ['https://images.unsplash.com/photo-1615485240384-1d0a8527a20c'] },
      { title: 'Coriander Seeds (Dhaniya)', description: 'Sun-dried aromatic coriander seeds.', category: 'Local Goods', price: 120, stock: 200, vendorId: v[3]._id, vendorName: v[3].fullName, location: v[3].address, images: ['https://images.unsplash.com/photo-1599940859674-a7fef05b94ae'] },
      { title: 'Red Chili Flakes (Khursani)', description: 'Extra spicy dried red chilies from Akabare variety.', category: 'Local Goods', price: 250, stock: 100, vendorId: v[3]._id, vendorName: v[3].fullName, location: v[3].address, images: ['https://images.unsplash.com/photo-1588165171080-c89acfa5ee83'] },

      // --- KATHMANDU SWEETS (Mithai) ---
      { title: 'Fresh Jalebi (Gwaramari)', description: 'Sweet, crispy, and syrupy traditional morning delight.', category: 'Others', price: 400, stock: 50, vendorId: v[4]._id, vendorName: v[4].fullName, location: v[4].address, images: ['https://images.unsplash.com/photo-1589114470455-8006734e5683'] },
      { title: 'Lakhamari (Newari Sweet)', description: 'Crunchy traditional Newari sweet made for celebrations.', category: 'Others', price: 650, stock: 30, vendorId: v[4]._id, vendorName: v[4].fullName, location: v[4].address, images: ['https://images.unsplash.com/photo-1605191661122-35bf383f900b'] },
      { title: 'Pustakari (Milk Candy)', description: 'Hard, chewy traditional Nepali candy made from milk and nuts.', category: 'Others', price: 500, stock: 100, vendorId: v[4]._id, vendorName: v[4].fullName, location: v[4].address, images: ['https://images.unsplash.com/photo-1582041236130-de8417158922'] },
      { title: 'Barfi (Milk Cake)', description: 'Soft and rich milk-based sweet fudge.', category: 'Others', price: 900, stock: 20, vendorId: v[4]._id, vendorName: v[4].fullName, location: v[4].address, images: ['https://images.unsplash.com/photo-1599921841143-819065a55cc6'] },
      { title: 'Sel Roti (Ring Bread)', description: 'Sweet rice-based ring bread, popular during Tihar.', category: 'Others', price: 40, stock: 500, vendorId: v[4]._id, vendorName: v[4].fullName, location: v[4].address, images: ['https://images.unsplash.com/photo-1605191660485-611388656d0e'] },

      // --- BHAKTAPUR POTTERY ---
      { title: 'Clay Yogurt Pot (Dhau Katora)', description: 'Authentic clay pot for making JuJu Dhau.', category: 'Handicrafts', price: 80, stock: 500, vendorId: v[5]._id, vendorName: v[5].fullName, location: v[5].address, images: ['https://images.unsplash.com/photo-1590073844006-3a4256d3df1e'] },
      { title: 'Terracotta Flower Vase', description: 'Hand-shaped and sun-fired terracotta vase.', category: 'Handicrafts', price: 1200, stock: 30, vendorId: v[5]._id, vendorName: v[5].fullName, location: v[5].address, images: ['https://images.unsplash.com/photo-1578500494198-246f612d3b3d'] },
      { title: 'Clay Tea Cups (Matka)', description: 'Set of 6 traditional clay cups for masala tea.', category: 'Handicrafts', price: 300, stock: 100, vendorId: v[5]._id, vendorName: v[5].fullName, location: v[5].address, images: ['https://images.unsplash.com/photo-1544739313-6fad02872377'] },
      { title: 'Miniature Pottery Set (Decor)', description: 'Set of 10 tiny traditional clay vessels.', category: 'Handicrafts', price: 550, stock: 20, vendorId: v[5]._id, vendorName: v[5].fullName, location: v[5].address, images: ['https://images.unsplash.com/photo-1581783898377-1c85bf937427'] },
      { title: 'Pala (Oil Lamp)', description: 'Clay oil lamps used for lighting during festivals.', category: 'Handicrafts', price: 10, stock: 1000, vendorId: v[5]._id, vendorName: v[5].fullName, location: v[5].address, images: ['https://images.unsplash.com/photo-1572941556006-25f058097d74'] },

      // --- LANGTANG DAIRY ---
      { title: 'Chhurpi (Hard Yak Cheese)', description: 'World\'s hardest cheese, great for chewing.', category: 'Dairy', price: 200, stock: 200, vendorId: v[6]._id, vendorName: v[6].fullName, location: v[6].address, images: ['https://images.unsplash.com/photo-1486299267070-83823f5448dd'] },
      { title: 'Soft Nak Cheese', description: 'Creamy and nutty cheese made from female yak (Nak) milk.', category: 'Dairy', price: 1800, stock: 10, vendorId: v[6]._id, vendorName: v[6].fullName, location: v[6].address, images: ['https://images.unsplash.com/photo-1452195100486-9cc805987862'] },
      { title: 'Local Cow Butter', description: 'Freshly churned mountain cow butter.', category: 'Dairy', price: 1100, stock: 30, vendorId: v[6]._id, vendorName: v[6].fullName, location: v[6].address, images: ['https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d'] },
      { title: 'Khuwa (Milk Solids)', description: 'Freshly prepared khuwa for making sweets at home.', category: 'Dairy', price: 900, stock: 15, vendorId: v[6]._id, vendorName: v[6].fullName, location: v[6].address, images: ['https://images.unsplash.com/photo-1550583724-b2692b85b150'] },
      { title: 'Paneer (Cottage Cheese)', description: 'Soft and fresh homemade paneer.', category: 'Dairy', price: 800, stock: 25, vendorId: v[6]._id, vendorName: v[6].fullName, location: v[6].address, images: ['https://images.unsplash.com/photo-1563223552-30d01fda3ead'] },

      // --- PALPALI DHAKA ---
      { title: 'Palpali Dhaka Shawl', description: 'Hand-woven Palpali Dhaka shawl with classic patterns.', category: 'Clothing', price: 2500, stock: 15, vendorId: v[7]._id, vendorName: v[7].fullName, location: v[7].address, images: ['https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b'] },
      { title: 'Dhaka Purse', description: 'Handy coin purse made from colourful Dhaka fabric.', category: 'Clothing', price: 350, stock: 50, vendorId: v[7]._id, vendorName: v[7].fullName, location: v[7].address, images: ['https://images.unsplash.com/photo-1566150905458-1bf1fc113f0d'] },
      { title: 'Dhaka Waistcoat (Daura Suruwal)', description: 'Men\'s traditional waistcoat in Palpali Dhaka.', category: 'Clothing', price: 3200, stock: 8, vendorId: v[7]._id, vendorName: v[7].fullName, location: v[7].address, images: ['https://images.unsplash.com/photo-1594932224828-b4b05928ffb8'] },
      { title: 'Hand-woven Dhaka Fabric (Per Meter)', description: 'Raw Dhaka fabric for custom tailoring.', category: 'Clothing', price: 1200, stock: 100, vendorId: v[7]._id, vendorName: v[7].fullName, location: v[7].address, images: ['https://images.unsplash.com/photo-1528459801416-a9e53bbf4e17'] },
      { title: 'Dhaka Cushion Covers (Set of 2)', description: 'Elegant cushion covers for home decor.', category: 'Clothing', price: 1500, stock: 20, vendorId: v[7]._id, vendorName: v[7].fullName, location: v[7].address, images: ['https://images.unsplash.com/photo-1584184924103-e310d9dc85fc'] },

      // --- JUMLA ORGANIC ---
      { title: 'Jumla Marshi Rice', description: 'The famous cold-resistant brown rice from the high altitudes of Jumla.', category: 'Local Goods', price: 350, stock: 500, vendorId: v[8]._id, vendorName: v[8].fullName, location: v[8].address, images: ['https://images.unsplash.com/photo-1586201375761-83865001e31c'] },
      { title: 'Walnuts from Jumla (Okhar)', description: 'Large, thin-shelled organic walnuts.', category: 'Local Goods', price: 800, stock: 100, vendorId: v[8]._id, vendorName: v[8].fullName, location: v[8].address, images: ['https://images.unsplash.com/photo-1585445497203-2a5b2e02ee1d'] },
      { title: 'Organic Beans (Simi)', description: 'Mixed mountain beans, rich in protein.', category: 'Local Goods', price: 250, stock: 200, vendorId: v[8]._id, vendorName: v[8].fullName, location: v[8].address, images: ['https://images.unsplash.com/photo-1551462147-37885abb3e9a'] },
      { title: 'Local Honey (Wild)', description: 'Unfiltered, raw honey collected from cliffs of Jumla.', category: 'Local Goods', price: 1500, stock: 30, vendorId: v[8]._id, vendorName: v[8].fullName, location: v[8].address, images: ['https://images.unsplash.com/photo-1587049352846-4a222e784d38'] },
      { title: 'Dried Chilies (Jumla Red)', description: 'Extremely spicy sun-dried mountain chilies.', category: 'Local Goods', price: 400, stock: 50, vendorId: v[8]._id, vendorName: v[8].fullName, location: v[8].address, images: ['https://images.unsplash.com/photo-1514327605112-b887c0e61c0a'] },

      // --- HIMALAYAN WOOLENS ---
      { title: '100% Pure Pashmina Shawl', description: 'Authentic Chyangra Pashmina, ultra-soft and warm.', category: 'Clothing', price: 18000, stock: 5, vendorId: v[9]._id, vendorName: v[9].fullName, location: v[9].address, images: ['https://images.unsplash.com/photo-1606760227091-3dd870d97f1d'] },
      { title: 'Sheep Wool Blanket (Radi)', description: 'Traditional heavy wool blanket from the mountains.', category: 'Clothing', price: 6500, stock: 10, vendorId: v[9]._id, vendorName: v[9].fullName, location: v[9].address, images: ['https://images.unsplash.com/photo-1580302521144-18779c83d9a1'] },
      { title: 'Hand-knitted Woolen Mittens', description: 'Warm mittens made from local sheep wool.', category: 'Clothing', price: 450, stock: 40, vendorId: v[9]._id, vendorName: v[9].fullName, location: v[9].address, images: ['https://images.unsplash.com/photo-1516733968668-dbdce39c46ef'] },
      { title: 'YAK Wool Scarf', description: 'Durable and warm scarf made from refined Yak wool.', category: 'Clothing', price: 1500, stock: 25, vendorId: v[9]._id, vendorName: v[9].fullName, location: v[9].address, images: ['https://images.unsplash.com/photo-1520903920243-00d872a2d1c9'] },
      { title: 'Felt Wool Shoes (Home)', description: 'Comfortable indoor slippers made from felted wool.', category: 'Clothing', price: 1200, stock: 20, vendorId: v[9]._id, vendorName: v[9].fullName, location: v[9].address, images: ['https://images.unsplash.com/photo-1543163521-1bf539c55dd2'] }
    ];

    await Product.insertMany(products);
    console.log(`✅ Created ${products.length} Authenticated Local Products`);

    console.log('\n--- Full-Fledged Prototype Seeded ---');
    console.log('Total Vendors: 10');
    console.log('Total Products: 50');
    console.log('Categories Covered: Vegetables, Dairy, Handicrafts, Clothing, Local Goods, Others');
    
    await mongoose.connection.close();
  } catch (err) {
    console.error('Error:', err.message);
    process.exit(1);
  }
};

seedData();
