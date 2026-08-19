import express from 'express';
import * as feedbackController from '../controllers/feedbackController';
import { protect, restrictTo } from '../middleware/authMiddleware';

const router = express.Router();

router.use(protect);

router.post('/', feedbackController.submitFeedback);
router.get('/', restrictTo('admin'), feedbackController.getAllFeedback);

export = router;
