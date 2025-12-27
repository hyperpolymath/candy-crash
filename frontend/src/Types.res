// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2025 Hyperpolymath

type course = {
  key: string,
  title: string,
  description: option<string>,
  categoryKey: string,
  instructorKey: string,
  price: float,
  durationHours: int,
  level: string,
  published: bool,
  slug: string,
  thumbnailUrl: option<string>,
}

type category = {
  key: string,
  name: string,
  description: option<string>,
  slug: string,
  position: int,
}

type courseModule = {
  key: string,
  courseKey: string,
  title: string,
  description: option<string>,
  position: int,
  published: bool,
  lessons: array<lessonSummary>,
}
and lessonSummary = {
  key: string,
  title: string,
  lessonType: string,
  position: int,
  durationMinutes: int,
}

type courseDetail = {
  key: string,
  title: string,
  description: option<string>,
  category: option<category>,
  instructor: option<instructor>,
  price: float,
  durationHours: int,
  level: string,
  modules: array<courseModule>,
  quizzes: array<quizSummary>,
}
and instructor = {
  key: string,
  email: string,
}
and quizSummary = {
  key: string,
  title: string,
  quizType: string,
  passingScore: int,
}

type lesson = {
  key: string,
  moduleKey: string,
  title: string,
  content: option<string>,
  lessonType: string,
  position: int,
  durationMinutes: int,
  videoUrl: option<string>,
  prevLesson: option<string>,
  nextLesson: option<string>,
  progress: option<lessonProgress>,
}
and lessonProgress = {
  key: string,
  completed: bool,
  completedAt: option<string>,
  timeSpentMinutes: int,
}

type quiz = {
  key: string,
  courseKey: string,
  title: string,
  description: option<string>,
  passingScore: int,
  timeLimitMinutes: option<int>,
  quizType: string,
  maxAttempts: option<int>,
  attemptsCount: int,
  bestScore: option<float>,
}

type question = {
  key: string,
  content: string,
  questionType: string,
  points: int,
  options: array<questionOption>,
}
and questionOption = {
  key: string,
  content: string,
  position: int,
}

type quizAttempt = {
  key: string,
  quizKey: string,
  score: option<float>,
  startedAt: string,
  completedAt: option<string>,
  passed: option<bool>,
}

type enrollment = {
  key: string,
  userKey: string,
  courseKey: string,
  enrolledAt: string,
  completedAt: option<string>,
  progress: int,
  status: string,
}

type achievement = {
  key: string,
  title: string,
  description: option<string>,
  badgeType: string,
  points: int,
  badgeImageUrl: option<string>,
}

type userAchievement = {
  key: string,
  achievementKey: string,
  earnedAt: string,
  achievement: option<achievement>,
}

// Training Loop Types
type microSkill = {
  id: string,
  name: string,
  description: string,
  domain: string,
  saLevel: string,
  ambientTrainable: bool,
  modalities: array<string>,
}

type skillState = {
  skillId: string,
  competence: float,
  confidence: float,
  lastTrained: option<string>,
  lastAssessed: option<string>,
  attemptCount: int,
  successCount: int,
}

type competenceModel = {
  key: option<string>,
  userKey: string,
  domain: string,
  skills: array<skillState>,
}

type interventionContent = {
  @as("type") contentType: string,
  gapStartMs: option<int>,
  gapEndMs: option<int>,
  approachDurationMs: option<int>,
}

type intervention = {
  id: string,
  targetSkillId: string,
  modality: string,
  difficulty: float,
  content: interventionContent,
  expectedDurationMs: int,
}

type interventionResult = {
  interventionId: string,
  deliveredAt: string,
  responseTimeMs: option<int>,
  outcome: string,
}

type trainingSession = {
  key: option<string>,
  userKey: string,
  domain: string,
  startedAt: string,
  endedAt: option<string>,
  status: string,
  initialActivity: string,
  interventions: array<interventionResult>,
}

type traineeState = {
  activity: string,
  attention: string,
  lastInterventionAt: option<string>,
  sessionInterventionCount: int,
}

type sessionSummary = {
  totalInterventions: int,
  correctResponses: int,
  accuracy: float,
}

type interventionResponse = {
  outcome: string,
  newCompetence: float,
  feedback: string,
}
