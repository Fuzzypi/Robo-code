const STORE_KEY = 'crm_store_v1';

function getInitialState() {
  return {
    customers: [
      { id: 1, name: 'Acme Corp', email: 'contact@acme.com', phone: '555-0100' },
      { id: 2, name: 'Globex Inc', email: 'info@globex.com', phone: '555-0200' },
      { id: 3, name: 'Initech Ltd', email: 'hello@initech.com', phone: '555-0300' },
      { id: 4, name: 'Umbrella Corporation', email: 'lab@umbrella.com', phone: '555-0400' },
      { id: 5, name: 'Stark Industries', email: 'tony@stark.com', phone: '555-0500' },
      { id: 6, name: 'Wayne Enterprises', email: 'alfred@wayne.com', phone: '555-0600' },
      { id: 7, name: 'Oscorp Industries', email: 'admin@oscorp.com', phone: '555-0700' },
      { id: 8, name: 'Dunder Mifflin', email: 'sales@dundermifflin.com', phone: '555-0800' }
    ],
    jobs: [
      {
        id: 1,
        customerId: 1,
        description: 'Install new HVAC system',
        scheduledAt: '2026-02-10T09:00',
        status: 'pending',
        createdAt: new Date().toISOString()
      },
      {
        id: 2,
        customerId: 1,
        description: 'Annual maintenance check',
        scheduledAt: '2026-03-15T14:00',
        status: 'scheduled',
        createdAt: new Date().toISOString()
      },
      {
        id: 3,
        customerId: 2,
        description: 'Replace water heater',
        scheduledAt: '2026-02-12T10:30',
        status: 'pending',
        createdAt: new Date().toISOString()
      },
      {
        id: 4,
        customerId: 2,
        description: 'Fix leaking faucet in break room',
        scheduledAt: '2026-02-08T13:00',
        status: 'completed',
        createdAt: new Date().toISOString()
      },
      {
        id: 5,
        customerId: 3,
        description: 'Install security cameras',
        scheduledAt: '2026-02-20T09:00',
        status: 'scheduled',
        createdAt: new Date().toISOString()
      },
      {
        id: 6,
        customerId: 4,
        description: 'Lab ventilation system upgrade',
        scheduledAt: '2026-02-25T08:00',
        status: 'pending',
        createdAt: new Date().toISOString()
      },
      {
        id: 7,
        customerId: 5,
        description: 'Arc reactor cooling system maintenance',
        scheduledAt: '2026-02-14T11:00',
        status: 'scheduled',
        createdAt: new Date().toISOString()
      },
      {
        id: 8,
        customerId: 6,
        description: 'Batcave HVAC repair',
        scheduledAt: '2026-02-18T22:00',
        status: 'pending',
        createdAt: new Date().toISOString()
      },
      {
        id: 9,
        customerId: 7,
        description: 'Emergency power backup installation',
        scheduledAt: '2026-02-11T09:30',
        status: 'in_progress',
        createdAt: new Date().toISOString()
      },
      {
        id: 10,
        customerId: 8,
        description: 'Office plumbing inspection',
        scheduledAt: '2026-02-16T10:00',
        status: 'scheduled',
        createdAt: new Date().toISOString()
      }
    ],
    notes: [
      {
        id: 1,
        parentType: 'customer',
        parentId: 1,
        text: 'Prefers morning appointments. Main contact is Wile E. Coyote.',
        createdAt: new Date().toISOString()
      },
      {
        id: 2,
        parentType: 'customer',
        parentId: 1,
        text: 'Building requires security clearance for roof access.',
        createdAt: new Date().toISOString()
      },
      {
        id: 3,
        parentType: 'job',
        parentId: 1,
        text: 'Customer requested energy-efficient units. Quote approved $15,000.',
        createdAt: new Date().toISOString()
      },
      {
        id: 4,
        parentType: 'customer',
        parentId: 2,
        text: 'Net 30 payment terms. Contact: Hank Scorpio.',
        createdAt: new Date().toISOString()
      },
      {
        id: 5,
        parentType: 'job',
        parentId: 3,
        text: 'Water heater located in basement. Parking available in rear.',
        createdAt: new Date().toISOString()
      },
      {
        id: 6,
        parentType: 'job',
        parentId: 4,
        text: 'Job completed successfully. Customer very satisfied.',
        createdAt: new Date().toISOString()
      },
      {
        id: 7,
        parentType: 'customer',
        parentId: 3,
        text: 'Office hours 9-5. Ask for Bill Lumbergh at reception.',
        createdAt: new Date().toISOString()
      },
      {
        id: 8,
        parentType: 'customer',
        parentId: 4,
        text: 'HIGH PRIORITY. Biohazard protocols required. PPE mandatory.',
        createdAt: new Date().toISOString()
      },
      {
        id: 9,
        parentType: 'job',
        parentId: 6,
        text: 'Specialized ventilation filters needed. Order part #UV-9000.',
        createdAt: new Date().toISOString()
      },
      {
        id: 10,
        parentType: 'customer',
        parentId: 5,
        text: 'VIP client. Direct line to Tony Stark. Premium service level.',
        createdAt: new Date().toISOString()
      },
      {
        id: 11,
        parentType: 'job',
        parentId: 7,
        text: 'Arc reactor generates high heat. Custom cooling solution required.',
        createdAt: new Date().toISOString()
      },
      {
        id: 12,
        parentType: 'customer',
        parentId: 6,
        text: 'After hours only. Access via secret entrance. Alfred will coordinate.',
        createdAt: new Date().toISOString()
      },
      {
        id: 13,
        parentType: 'job',
        parentId: 8,
        text: 'Work must be completed between 10pm-6am. No questions asked.',
        createdAt: new Date().toISOString()
      },
      {
        id: 14,
        parentType: 'customer',
        parentId: 7,
        text: 'Research facility. Norman Osborn approval required for all work.',
        createdAt: new Date().toISOString()
      },
      {
        id: 15,
        parentType: 'customer',
        parentId: 8,
        text: 'Paper company. Very friendly staff. Michael Scott is regional manager.',
        createdAt: new Date().toISOString()
      },
      {
        id: 16,
        parentType: 'job',
        parentId: 10,
        text: 'Dwight insists on being present during inspection. Bring beets.',
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
