import type { ConsultantProfile } from './types';

// 入驻只采集审核和主页初始化所需的最小字段；个人主页与档案是唯一完整数据源。
export type CounselorOnboardingProfileSeed = Pick<
  ConsultantProfile,
  'name' | 'title' | 'experienceYears' | 'totalHours' | 'orientations' | 'bio'
> & Pick<ConsultantProfile, 'qualificationsList' | 'educationList' | 'trainingExperiences'>;

export const applyOnboardingSeed = (
  profile: ConsultantProfile,
  seed: CounselorOnboardingProfileSeed,
): ConsultantProfile => ({
  ...profile,
  ...seed,
  // 入驻完成后仍由“个人主页与档案”维护其余扩展字段，不清空既有默认值。
  qualificationsList: seed.qualificationsList ?? profile.qualificationsList,
  educationList: seed.educationList ?? profile.educationList,
  trainingExperiences: seed.trainingExperiences ?? profile.trainingExperiences,
});
