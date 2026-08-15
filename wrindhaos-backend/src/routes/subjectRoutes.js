const express = require('express');
const router = express.Router();
const subjectController = require('../controllers/subjectController');
const { authenticateUser } = require('../middleware/authMiddleware');
const { enforceFeatureLimit } = require('../middleware/premiumMiddleware');
const { validateBody } = require('../middleware/validationMiddleware');
const { FEATURES } = require('../constants/entitlements');

router.use(authenticateUser);

router.get('/', subjectController.getSubjects);
router.post(
  '/',
  validateBody(['title']),
  enforceFeatureLimit(FEATURES.SUBJECTS, subjectController.getUserSubjectCount, 'SUBJECT_LIMIT_REACHED'),
  subjectController.createSubject
);
router.get('/:id', subjectController.getSubjectById);
router.patch('/:id', subjectController.updateSubject);
router.delete('/:id', subjectController.deleteSubject);

module.exports = router;
