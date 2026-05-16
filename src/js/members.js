const MEMBERS = {
  bei:     { id: 'bei',     name: '貝',   role: '我',   color: '#5BB8E8', emoji: '☁️' },
  qun:     { id: 'qun',     name: '群',   role: '先生', color: '#7B5EA7', emoji: '🌙' },
  az:      { id: 'az',      name: 'AZ',   role: '兒子', color: '#1A3A6B', emoji: '🚀' },
  emma:    { id: 'emma',    name: 'Emma', role: '女兒', color: '#F4A7B9', emoji: '🌸' },
  grandpa: { id: 'grandpa', name: '爺爺', role: '公公', color: '#2D6A2D', emoji: '🌲' },
  grandma: { id: 'grandma', name: '阿嬤', role: '婆婆', color: '#6AAB5E', emoji: '🌿' },
  uncle:   { id: 'uncle',   name: '叔叔', role: '其他', color: '#E8943A', emoji: '🍊' },
};

const MEMBER_LIST = Object.values(MEMBERS);

function getMember(id) {
  return MEMBERS[id] || { id, name: id, color: '#AAAAAA', emoji: '👤' };
}

function memberDot(id, size = 10) {
  const m = getMember(id);
  return `<span class="member-dot" style="background:${m.color};width:${size}px;height:${size}px;" title="${m.name}"></span>`;
}

function memberBadge(id) {
  const m = getMember(id);
  return `<span class="member-badge" style="background:${m.color}20;color:${m.color};border:1px solid ${m.color}40;">${m.emoji} ${m.name}</span>`;
}
