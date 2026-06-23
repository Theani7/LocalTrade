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
    // Clear all existing products and specific mock vendors (both old and new sets)
    await User.deleteMany({ email: { $in: [
      'farm@example.com', 'crafts@example.com', 'dairy@example.com', 'clothing@example.com',
      'spices@example.com', 'tea@example.com', 'sweets@example.com', 'bakery@example.com',
      'localgoods@example.com', 'pottery@example.com',
      'himalayan@example.com', 'mithila@example.com', 'everest@example.com', 'terai@example.com',
      'patan@example.com', 'ilam@example.com', 'kathmandu@example.com', 'dhankuta@example.com',
      'jumla@example.com', 'eastern@example.com'
    ]}});
    await Product.deleteMany({});

    console.log('Ensuring default admin exists...');
    const adminEmail = 'admin@gmail.com';
    const adminPassword = 'admin123';
    await User.deleteOne({ email: adminEmail });
    await User.create({
      fullName: 'System Admin',
      email: adminEmail,
      phone: '9800000000',
      password: adminPassword,
      address: {
        fullName: 'System Admin',
        phone: '9800000000',
        city: 'Kathmandu',
        state: 'Bagmati',
        zipCode: '44600',
      },
      role: 'admin',
      isActive: true,
      vendorApprovalStatus: 'approved'
    });
    console.log(`✅ Default Admin ready: ${adminEmail}`);

    console.log('Creating 10 Local Vendors...');
    const password = await bcrypt.hash('password123', 12);

    const vendorsData = [
      { fullName: 'Himalayan Treasures', email: 'himalayan@example.com', phone: '9841000001', password, address: 'Manang, Nepal', role: 'vendor', vendorApprovalStatus: 'approved' },
      { fullName: 'Mithila Art Hub', email: 'mithila@example.com', phone: '9841000002', password, address: 'Janakpur, Nepal', role: 'vendor', vendorApprovalStatus: 'approved' },
      { fullName: 'Everest Organic Dairy', email: 'everest@example.com', phone: '9841000003', password, address: 'Solukhumbu, Nepal', role: 'vendor', vendorApprovalStatus: 'approved' },
      { fullName: 'Terai Fresh Fruits', email: 'terai@example.com', phone: '9841000004', password, address: 'Saptari, Nepal', role: 'vendor', vendorApprovalStatus: 'approved' },
      { fullName: 'Patan Craft Studio', email: 'patan@example.com', phone: '9841000005', password, address: 'Lalitpur, Nepal', role: 'vendor', vendorApprovalStatus: 'approved' },
      { fullName: 'Ilam Tea Estate', email: 'ilam@example.com', phone: '9841000006', password, address: 'Ilam, Nepal', role: 'vendor', vendorApprovalStatus: 'approved' },
      { fullName: 'Kathmandu Organic Spices', email: 'kathmandu@example.com', phone: '9841000007', password, address: 'Asan, Kathmandu', role: 'vendor', vendorApprovalStatus: 'approved' },
      { fullName: 'Dhankuta Woodworks', email: 'dhankuta@example.com', phone: '9841000008', password, address: 'Dhankuta, Nepal', role: 'vendor', vendorApprovalStatus: 'approved' },
      { fullName: 'Jumla Marshi Depot', email: 'jumla@example.com', phone: '9841000009', password, address: 'Jumla, Nepal', role: 'vendor', vendorApprovalStatus: 'approved' },
      { fullName: 'Eastern Bamboo Crafts', email: 'eastern@example.com', phone: '9841000010', password, address: 'Taplejung, Nepal', role: 'vendor', vendorApprovalStatus: 'approved' }
    ];

    const createdVendors = await User.insertMany(vendorsData);
    const v = createdVendors;

    console.log('Creating New Local Products...');

    const products = [
      { title: 'Hand-Woven Bamboo Doko', description: 'A traditional Nepali carrying basket, masterfully hand-woven from resilient mountain bamboo. Perfect for rustic interior decor or as a sturdy, eco-friendly carrier for garden and market use.', category: 'Handicrafts', price: 1200, stock: 30, vendorId: v[9]._id, vendorName: v[9].fullName, location: v[9].address, images: ['https://images.unsplash.com/photo-1511119253456-4299b9087599'] },
      { title: 'Pure Himalayan Yak Ghee', description: 'Nutritious, golden ghee churned from the milk of free-roaming Yaks in the Everest region. Known for its distinct nutty aroma and rich texture, it is a staple for both Ayurvedic health and gourmet Nepali cuisine.', category: 'Dairy', price: 2500, stock: 50, vendorId: v[2]._id, vendorName: v[2].fullName, location: v[2].address, images: ['https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d'] },
      { title: 'Authentic Mithila Wall Art', description: 'Exquisite hand-painted folk art created by the women of Janakpur. Each vibrant piece uses natural pigments to depict traditional folklore, nature, and Mithila culture, making it a unique heritage decor item.', category: 'Handicrafts', price: 3500, stock: 15, vendorId: v[1]._id, vendorName: v[1].fullName, location: v[1].address, images: ['https://images.unsplash.com/photo-1579783902614-a3fb3927b6a5'] },
      { title: 'Sweet Saptari Malda Mangoes', description: 'Experience the legendary "King of Fruits" from the sun-drenched plains of Saptari. These Malda mangoes are naturally ripened, incredibly juicy, and offer an unparalleled sweetness. Delivered in a 5kg farm-fresh crate.', category: 'Vegetables', price: 1500, stock: 100, vendorId: v[3]._id, vendorName: v[3].fullName, location: v[3].address, images: ['https://images.unsplash.com/photo-1553279768-865429fa0078'] },
      { title: 'Hand-Beaten Singing Bowl', description: 'An authentic 7-metal alloy singing bowl, hand-hammered by artisans in Patan. Produces a deep, harmonic resonance that is ideal for meditation, sound healing, and creating a tranquil atmosphere.', category: 'Handicrafts', price: 4500, stock: 20, vendorId: v[4]._id, vendorName: v[4].fullName, location: v[4].address, images: ['https://images.unsplash.com/photo-1594122230689-45899d9e6f69'] },
      { title: 'Ilam First Flush Green Tea', description: 'Sourced from the high-altitude misty gardens of Ilam, this first flush green tea is rich in antioxidants. It offers a delicate floral aroma and a clean, refreshing taste that captures the essence of the Himalayas.', category: 'Local Goods', price: 850, stock: 80, vendorId: v[5]._id, vendorName: v[5].fullName, location: v[5].address, images: ['https://images.unsplash.com/photo-1594631252845-59fc5973f7d8'] },
      { title: 'Organic Wild Himalayan Jimbu', description: 'A rare, aromatic herb hand-picked from the dry highlands of Mustang. When tempered in ghee, this wild allium releases a unique, savory fragrance essential for authentic Nepali Dal Bhat.', category: 'Local Goods', price: 250, stock: 200, vendorId: v[6]._id, vendorName: v[6].fullName, location: v[6].address, images: ['https://images.unsplash.com/photo-1509358271058-acd22cc93898'] },
      { title: 'Dhankuta Traditional Khukuri', description: 'The legendary blade of Nepal, hand-forged by hereditary blacksmiths in Dhankuta. Features a beautifully carved wooden handle and a high-carbon steel blade, representing both a functional tool and a symbol of bravery.', category: 'Handicrafts', price: 5500, stock: 10, vendorId: v[7]._id, vendorName: v[7].fullName, location: v[7].address, images: ['https://images.unsplash.com/photo-1594132039203-094776106c54'] },
      { title: 'Jumla Red Marshi Rice (5kg)', description: 'Historical red rice variety grown at the highest altitudes in the world. Renowned for its unique nutty flavor, soft texture, and high nutritional value, it was once reserved for royalty.', category: 'Local Goods', price: 1800, stock: 60, vendorId: v[8]._id, vendorName: v[8].fullName, location: v[8].address, images: ['https://images.unsplash.com/photo-1586201375761-83865001e31c'] },
      { title: 'Eco-Friendly Allo Tote Bag', description: 'A durable and stylish tote bag crafted from wild Himalayan Nettle (Allo) fibers. This sustainable accessory is 100% natural, hand-spun, and supports local weaving communities in the mountain regions.', category: 'Clothing', price: 1500, stock: 40, vendorId: v[0]._id, vendorName: v[0].fullName, location: v[0].address, images: ['https://images.unsplash.com/photo-1523381210434-271e8be1f52b'] },
      { title: 'Bhaktapur Pottery Flower Vase', description: 'A timeless terracotta vase, hand-thrown on a traditional potter\'s wheel in the ancient city of Bhaktapur. Its earthy texture and classic silhouette bring a touch of Nepali tradition to any modern home.', category: 'Handicrafts', price: 900, stock: 25, vendorId: v[4]._id, vendorName: v[4].fullName, location: v[4].address, images: ['https://images.unsplash.com/photo-1578500494198-246f612d3b3d'] },
      { title: 'Pure Shilajit (50g)', description: 'A potent, mineral-rich resin harvested from the high-altitude Himalayan rocks. Known as the "Destroyer of Weakness," this authentic Shilajit is a traditional Ayurvedic supplement for energy, vitality, and overall well-being.', category: 'Local Goods', price: 3200, stock: 30, vendorId: v[0]._id, vendorName: v[0].fullName, location: v[0].address, images: ['https://images.unsplash.com/photo-1512061290327-14781448123b'] },
      { title: 'Local Honey from Mustang', description: 'Raw, unfiltered honey collected by traditional honey hunters from wild beehives on the cliffs of Mustang. Infused with the nectar of high-altitude wildflowers, it offers a complex and pure mountain flavor.', category: 'Local Goods', price: 1200, stock: 45, vendorId: v[0]._id, vendorName: v[0].fullName, location: v[0].address, images: ['https://images.unsplash.com/photo-1587049352846-4a222e784d38'] },
      { title: 'Handmade Lokta Paper Notebook', description: 'Crafted from the bark of the Daphne plant, this Lokta paper notebook is acid-free and exceptionally durable. Its unique, textured surface is perfect for journaling, sketching, or gifting as a piece of eco-friendly art.', category: 'Handicrafts', price: 450, stock: 120, vendorId: v[1]._id, vendorName: v[1].fullName, location: v[1].address, images: ['https://images.unsplash.com/photo-1544816155-12df9643f363'] },
      { title: 'Palpali Dhaka Topi', description: 'The iconic Nepali cap, hand-woven with intricate geometric patterns using traditional Dhaka fabric. Each Topi is a masterpiece of Palpali craftsmanship, representing national identity and cultural pride.', category: 'Clothing', price: 800, stock: 50, vendorId: v[7]._id, vendorName: v[7].fullName, location: v[7].address, images: ['https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b'] },
      { title: 'Himalayan Pink Salt (1kg)', description: 'Pristine, unrefined pink salt mined from the Himalayan foothills. Rich in 84 essential minerals, it enhances the flavor of your meals while providing a healthier alternative to processed table salt.', category: 'Local Goods', price: 150, stock: 200, vendorId: v[0]._id, vendorName: v[0].fullName, location: v[0].address, images: ['https://images.unsplash.com/photo-1626131731323-66459cf44b62'] },
      { title: 'Dried Akabare Khursani', description: 'Fiery and aromatic "Round Chilies" from the hills of Nepal. These dried Akabare chilies are famous for their intense heat and distinct fruity undertones, perfect for making potent local pickles and hot sauces.', category: 'Vegetables', price: 400, stock: 100, vendorId: v[6]._id, vendorName: v[6].fullName, location: v[6].address, images: ['https://images.unsplash.com/photo-1588165171080-c89acfa5ee83'] },
      { title: 'Handcrafted Wooden Theki', description: 'A traditional wooden vessel essential for any authentic Nepali kitchen. Hand-carved from durable wood, it is traditionally used for churning fresh yogurt into aromatic butter and buttermilk.', category: 'Handicrafts', price: 1800, stock: 12, vendorId: v[7]._id, vendorName: v[7].fullName, location: v[7].address, images: ['https://images.unsplash.com/photo-1590073844006-3a4256d3df1e'] },
      { title: 'Organic Buckwheat Flour', description: 'Nutritious, gluten-free flour milled from buckwheat grown in the high-altitude fields of Mustang. Ideal for making traditional Nepali flatbreads (Phapar ko Roti) and healthy, fiber-rich meals.', category: 'Local Goods', price: 300, stock: 150, vendorId: v[8]._id, vendorName: v[8].fullName, location: v[8].address, images: ['https://images.unsplash.com/photo-1509440159596-0249088772ff'] },
      { title: 'Tibetan Prayer Flags (Set of 5)', description: 'Colorful cotton flags inscribed with sacred mantras and symbols. Traditionally hung to spread peace, compassion, and strength as the wind carries the prayers across the landscape.', category: 'Others', price: 350, stock: 500, vendorId: v[0]._id, vendorName: v[0].fullName, location: v[0].address, images: ['https://images.unsplash.com/photo-1544124499-58912cbddaad'] },
      { title: 'Fresh Gundruk (Dried Greens)', description: 'A beloved Nepali delicacy made from fermented and sun-dried leafy greens. Known for its tangy flavor profile, Gundruk is used to make a soul-warming soup that is both appetizing and nutritious.', category: 'Local Goods', price: 200, stock: 300, vendorId: v[6]._id, vendorName: v[6].fullName, location: v[6].address, images: ['https://images.unsplash.com/photo-1512621776951-a57141f2eefd'] },
      { title: 'Hand-Woven Dhaka Shawl', description: 'An elegant shawl featuring the intricate and colorful patterns of Palpali Dhaka. Hand-loomed with precision, this soft and warm accessory is perfect for adding a touch of Nepali heritage to any outfit.', category: 'Clothing', price: 2200, stock: 20, vendorId: v[7]._id, vendorName: v[7].fullName, location: v[7].address, images: ['https://images.unsplash.com/photo-1584184924103-e310d9dc85fc'] },
      { title: 'Mustang Dried Apples (200g)', description: 'Sweet and crispy apple slices, naturally sun-dried in the crisp mountain air of Mustang. These chemical-free snacks preserve the intense flavor of high-altitude orchards, making them a healthy local treat.', category: 'Local Goods', price: 450, stock: 100, vendorId: v[0]._id, vendorName: v[0].fullName, location: v[0].address, images: ['https://images.unsplash.com/photo-1567306226416-28f0efdc88ce'] },
      { title: 'Handmade Copper Karuwa', description: 'A beautiful and functional piece of Newari metalwork. This pure copper water vessel is traditionally used for serving water or as a decorative art piece, featuring ornate hand-engraved details.', category: 'Handicrafts', price: 3800, stock: 15, vendorId: v[4]._id, vendorName: v[4].fullName, location: v[4].address, images: ['https://images.unsplash.com/photo-1584622650111-993a426fbf0a'] },
      { title: 'Organic Turmeric Powder', description: 'Pure, vibrant turmeric powder sourced from organic farms in the fertile Terai plains. High in curcumin, this "Golden Spice" is essential for its flavor, color, and powerful anti-inflammatory properties.', category: 'Local Goods', price: 180, stock: 500, vendorId: v[3]._id, vendorName: v[3].fullName, location: v[3].address, images: ['https://images.unsplash.com/photo-1615485240384-1d0a8527a20c'] },
      { title: 'Himalayan Nettle Tea', description: 'A refreshing herbal infusion made from wild-harvested Himalayan nettle leaves. This earthy, caffeine-free tea is traditionally prized for its detoxifying benefits and high mineral content.', category: 'Local Goods', price: 650, stock: 75, vendorId: v[5]._id, vendorName: v[5].fullName, location: v[5].address, images: ['https://images.unsplash.com/photo-1564890369478-c89ca6d9cde9'] },
      { title: 'Handcrafted Bamboo Lamp Shade', description: 'Illuminate your space with this modern lamp shade, intricately woven from sustainable bamboo by artisans in Eastern Nepal. Its geometric weave creates a beautiful play of light and shadow.', category: 'Handicrafts', price: 2500, stock: 10, vendorId: v[9]._id, vendorName: v[9].fullName, location: v[9].address, images: ['https://images.unsplash.com/photo-1534073828943-f801091bb18c'] },
      { title: 'Pure Nak Cheese (Yak Cheese)', description: 'A gourmet hard cheese made from the milk of female yaks (Nak). Aged to perfection, it features a nutty, complex flavor and a firm texture that is a true delicacy of the high Himalayas.', category: 'Dairy', price: 1800, stock: 25, vendorId: v[2]._id, vendorName: v[2].fullName, location: v[2].address, images: ['https://images.unsplash.com/photo-1452195100486-9cc805987862'] },
      { title: 'Hand-Carved Sandalwood Incense', description: 'Premium incense sticks crafted from natural sandalwood powder and essential oils. When lit, they release a calming, woody aroma that purifies the air and creates a peaceful environment for prayer or relaxation.', category: 'Others', price: 850, stock: 100, vendorId: v[4]._id, vendorName: v[4].fullName, location: v[4].address, images: ['https://images.unsplash.com/photo-1602192103300-47e66756152e'] },
      { title: 'Organic Ginger Powder', description: 'Zesty and pungent ginger powder made from organic roots grown in the Himalayan foothills. Perfect for adding a warm, spicy kick to your teas, curries, and traditional Nepali winter remedies.', category: 'Local Goods', price: 220, stock: 400, vendorId: v[6]._id, vendorName: v[6].fullName, location: v[6].address, images: ['https://images.unsplash.com/photo-1615485500704-8e990f9900f7'] }
    ];

    await Product.insertMany(products);
    console.log(`✅ Created ${products.length} New Authenticated Local Products`);

    console.log('\n--- Local Product Seed Completed ---');
    console.log(`Total Vendors: ${createdVendors.length}`);
    console.log(`Total Products: ${products.length}`);
    
    await mongoose.connection.close();
  } catch (err) {
    console.error('Error:', err.message);
    process.exit(1);
  }
};

seedData();
