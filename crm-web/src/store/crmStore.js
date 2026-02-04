const STORE_KEY = 'crm_store_v1';

function getInitialState() {
  return {
    customers: [
      { id: 1, name: 'Acme Corp', email: 'contact@acme.com', phone: '555-0100' },
      { id: 2, name: 'Globex Inc', email: 'info@globex.com', phone: '555-0200' },
      { id: 3, name: 'Initech Ltd', email: 'hello@initech.com', phone: '555-0300' }
    ],
    jobs: [
      {
        id: 1,
        customerId: 1,
        description: 'Install new HVAC system',
        scheduledAt: '2026-02-10T09:00',
        status: 'pending',
        createdAt: new Date().toISOString()
      }
    ],
    notes: [
      {
        id: 1,
        parentType: 'customer',
        parentId: 1,
        text: 'Prefers morning appointments',
        createdAt: new Date().toISOString()
      }
    ]
  };
}

export function loadStore() {
  const stored = localStorage.getItem(STORE_KEY);
  if (stored) {
    return JSON.parse(stored);
  }
  return getInitialState();
}

export function saveStore(state) {
  localStorage.setItem(STORE_KEY, JSON.stringify(state));
}

export function getCustomers(state) {
  return state.customers;
}

export function getCustomerById(state, id) {
  return state.customers.find(c => c.id === parseInt(id));
}

export function getJobsByCustomerId(state, customerId) {
  return state.jobs.filter(j => j.customerId === parseInt(customerId));
}

export function getNotesByParent(state, parentType, parentId) {
  return state.notes.filter(
    n => n.parentType === parentType && n.parentId === parseInt(parentId)
  );
}

export function addJob(state, job) {
  const newJob = {
    ...job,
    id: Math.max(0, ...state.jobs.map(j => j.id)) + 1,
    createdAt: new Date().toISOString()
  };
  state.jobs.push(newJob);
  saveStore(state);
  return newJob;
}

export function addNote(state, note) {
  const newNote = {
    ...note,
    id: Math.max(0, ...state.notes.map(n => n.id)) + 1,
    createdAt: new Date().toISOString()
  };
  state.notes.push(newNote);
  saveStore(state);
  return newNote;
}
