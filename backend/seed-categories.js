require('dotenv').config();
const mongoose = require('mongoose');
const Category = require('./src/models/categoryModel');

const defaults = [
  { name: 'Vegetables', icon: 'eco', sortOrder: 0 },
  { name: 'Dairy', icon: 'local_cafe', sortOrder: 1 },
  { name: 'Handicrafts', icon: 'palette', sortOrder: 2 },
  { name: 'Clothing', icon: 'checkroom', sortOrder: 3 },
  { name: 'Local Goods', icon: 'store', sortOrder: 4 },
  { name: 'Tailoring', icon: 'content_cut', sortOrder: 5 },
  { name: 'Groceries', icon: 'shopping_basket', sortOrder: 6 },
  { name: 'Bakery', icon: 'bakery_dining', sortOrder: 7 },
  { name: 'Meat', icon: 'set_meal', sortOrder: 8 },
  { name: 'Others', icon: 'more_horiz', sortOrder: 9 },
];

const seedCategories = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const existing = await Category.countDocuments();
    if (existing > 0) {
      console.log(`Database already has ${existing} categories. Skipping seed.`);
      await mongoose.connection.close();
      process.exit(0);
      return;
    }

    await Category.insertMany(defaults);
    console.log(`Seeded ${defaults.length} default categories`);
    await mongoose.connection.close();
    process.exit(0);
  } catch (err) {
    console.error('Error:', err.message);
    process.exit(1);
  }
};

seedCategories();
