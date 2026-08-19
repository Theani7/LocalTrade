import dotenv from 'dotenv';
dotenv.config();
import mongoose from 'mongoose';
import Category from './src/models/categoryModel';

interface DefaultCategory {
  name: string;
  icon: string;
  sortOrder: number;
}

const defaults: DefaultCategory[] = [
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

const seedCategories = async (): Promise<void> => {
  try {
    if (!process.env.MONGODB_URI) {
      throw new Error('MONGODB_URI must be set in .env');
    }
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
  } catch (err: any) {
    console.error('Error:', err.message);
    process.exit(1);
  }
};

seedCategories();
