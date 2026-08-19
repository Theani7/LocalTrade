import dotenv from 'dotenv';
dotenv.config();

import app from './app';
import connectDB from './config/db';
import mongoose from 'mongoose';
import { Server } from 'http';

process.on('uncaughtException', (err: Error) => {
  console.error('UNCAUGHT EXCEPTION! 💥 Shutting down...');
  console.error(err.name, err.message, err.stack);
  process.exit(1);
});

const PLACEHOLDER_SECRETS = ['your_super_secret_jwt_key_at_least_32_chars', 'your-jwt-secret', 'secret'];
if (process.env.NODE_ENV === 'production' && PLACEHOLDER_SECRETS.includes(process.env.JWT_SECRET as string)) {
  console.error('FATAL: JWT_SECRET is still set to a known placeholder value. Refusing to start.');
  process.exit(1);
}

const PORT = process.env.PORT || 5000;

let server: Server;

// Connect to Database and then start server
const startServer = async (): Promise<void> => {
  try {
    await connectDB();
    
    server = app.listen(PORT, () => {
      console.log(`🚀 Server running in ${process.env.NODE_ENV} mode on port ${PORT}`);
      console.log(`🔗 Health Check: http://localhost:${PORT}/health`);
    });
  } catch (error: any) {
    console.error('Failed to start server:', error.message);
    process.exit(1);
  }
};

startServer();

process.on('unhandledRejection', (err: any) => {
  console.error('UNHANDLED REJECTION! 💥 Shutting down...');
  console.error(err.name, err.message, err.stack);
  if (server) {
    server.close(() => {
      process.exit(1);
    });
  } else {
    process.exit(1);
  }
});

// Graceful shutdown
const gracefulShutdown = (): void => {
  console.log('SIGTERM/SIGINT received. Shutting down gracefully...');
  if (server) {
    server.close(() => {
      console.log('💥 Process terminated!');
      mongoose.connection.close().then(() => {
        process.exit(0);
      });
    });
  } else {
    process.exit(0);
  }
};

process.on('SIGTERM', gracefulShutdown);
process.on('SIGINT', gracefulShutdown);
