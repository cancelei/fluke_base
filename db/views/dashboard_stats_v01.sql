SELECT 
  u.id as user_id,
  u.email,
  
  -- Project stats
  COALESCE(p_stats.total_projects, 0) as total_projects,
  COALESCE(p_stats.projects_seeking_mentor, 0) as projects_seeking_mentor,
  COALESCE(p_stats.projects_seeking_cofounder, 0) as projects_seeking_cofounder,
  
  -- Agreement stats
  COALESCE(a_stats.total_agreements, 0) as total_agreements,
  COALESCE(a_stats.active_agreements, 0) as active_agreements,
  COALESCE(a_stats.completed_agreements, 0) as completed_agreements,
  COALESCE(a_stats.pending_agreements, 0) as pending_agreements,
  COALESCE(a_stats.agreements_as_initiator, 0) as agreements_as_initiator,
  COALESCE(a_stats.agreements_as_participant, 0) as agreements_as_participant,
  
  -- Meeting stats
  COALESCE(m_stats.total_meetings, 0) as total_meetings,
  COALESCE(m_stats.upcoming_meetings, 0) as upcoming_meetings,
  
  -- Milestone stats
  COALESCE(mil_stats.total_milestones, 0) as total_milestones,
  COALESCE(mil_stats.completed_milestones, 0) as completed_milestones,
  COALESCE(mil_stats.in_progress_milestones, 0) as in_progress_milestones,
  
  -- Timestamp for cache invalidation
  NOW() as calculated_at

FROM users u

-- Project statistics
LEFT JOIN (
  SELECT 
    user_id,
    COUNT(*) as total_projects,
    COUNT(CASE WHEN collaboration_type IN ('mentor', 'both') THEN 1 END) as projects_seeking_mentor,
    COUNT(CASE WHEN collaboration_type IN ('co-founder', 'both') THEN 1 END) as projects_seeking_cofounder
  FROM projects 
  GROUP BY user_id
) p_stats ON p_stats.user_id = u.id

-- Agreement statistics
LEFT JOIN (
  SELECT 
    ap.user_id,
    COUNT(*) as total_agreements,
    COUNT(CASE WHEN a.status = 'Accepted' THEN 1 END) as active_agreements,
    COUNT(CASE WHEN a.status = 'Completed' THEN 1 END) as completed_agreements,
    COUNT(CASE WHEN a.status = 'Pending' THEN 1 END) as pending_agreements,
    COUNT(CASE WHEN ap.is_initiator = true THEN 1 END) as agreements_as_initiator,
    COUNT(CASE WHEN ap.is_initiator = false THEN 1 END) as agreements_as_participant
  FROM agreement_participants ap
  JOIN agreements a ON a.id = ap.agreement_id
  GROUP BY ap.user_id
) a_stats ON a_stats.user_id = u.id

-- Meeting statistics
LEFT JOIN (
  SELECT 
    ap.user_id,
    COUNT(m.*) as total_meetings,
    COUNT(CASE WHEN m.start_time > NOW() THEN 1 END) as upcoming_meetings
  FROM agreement_participants ap
  JOIN agreements a ON a.id = ap.agreement_id
  LEFT JOIN meetings m ON m.agreement_id = a.id
  GROUP BY ap.user_id
) m_stats ON m_stats.user_id = u.id

-- Milestone statistics
LEFT JOIN (
  SELECT 
    p.user_id,
    COUNT(mil.*) as total_milestones,
    COUNT(CASE WHEN mil.status = 'completed' THEN 1 END) as completed_milestones,
    COUNT(CASE WHEN mil.status = 'in_progress' THEN 1 END) as in_progress_milestones
  FROM projects p
  LEFT JOIN milestones mil ON mil.project_id = p.id
  GROUP BY p.user_id
) mil_stats ON mil_stats.user_id = u.id;