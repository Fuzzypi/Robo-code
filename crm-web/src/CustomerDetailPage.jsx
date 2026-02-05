import { useParams, useNavigate } from 'react-router-dom';
import { useState, useEffect } from 'react';
import { clearToken } from './auth';
import {
  loadStore,
  getCustomerById,
  getJobsByCustomerId,
  getNotesByParent,
  addJob,
  addNote
} from './store/crmStore';

export function CustomerDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [store, setStore] = useState(null);
  const [customer, setCustomer] = useState(null);
  const [jobs, setJobs] = useState([]);
  const [customerNotes, setCustomerNotes] = useState([]);
  const [jobNotes, setJobNotes] = useState({});

  // Job form state
  const [jobDescription, setJobDescription] = useState('');
  const [jobScheduledAt, setJobScheduledAt] = useState('');

  // Note form state
  const [noteText, setNoteText] = useState('');
  const [noteTarget, setNoteTarget] = useState('customer');
  const [noteJobId, setNoteJobId] = useState('');

  const loadData = () => {
    const loadedStore = loadStore();
    setStore(loadedStore);
    
    const cust = getCustomerById(loadedStore, id);
    setCustomer(cust);

    const custJobs = getJobsByCustomerId(loadedStore, id);
    setJobs(custJobs);

    const custNotes = getNotesByParent(loadedStore, 'customer', id);
    setCustomerNotes(custNotes);

    const jNotes = {};
    custJobs.forEach(job => {
      jNotes[job.id] = getNotesByParent(loadedStore, 'job', job.id);
    });
    setJobNotes(jNotes);
  };

  useEffect(() => {
    loadData();
    // loadData depends on id but is defined inline, so we suppress the exhaustive-deps warning
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id]);

  const handleLogout = () => {
    clearToken();
    navigate('/login');
  };

  const handleAddJob = (e) => {
    e.preventDefault();
    
    if (!jobDescription.trim() || !jobScheduledAt) {
      alert('Please fill in all job fields');
      return;
    }

    const newJob = {
      customerId: parseInt(id),
      description: jobDescription.trim(),
      scheduledAt: jobScheduledAt,
      status: 'pending'
    };

    addJob(store, newJob);
    setJobDescription('');
    setJobScheduledAt('');
    loadData();
  };

  const handleAddNote = (e) => {
    e.preventDefault();

    if (!noteText.trim()) {
      alert('Please enter note text');
      return;
    }

    if (noteTarget === 'job' && !noteJobId) {
      alert('Please select a job');
      return;
    }

    const newNote = {
      parentType: noteTarget,
      parentId: noteTarget === 'customer' ? parseInt(id) : parseInt(noteJobId),
      text: noteText.trim()
    };

    addNote(store, newNote);
    setNoteText('');
    setNoteTarget('customer');
    setNoteJobId('');
    loadData();
  };

  if (!customer) {
    return <div style={{ padding: '2rem' }}>Customer not found</div>;
  }

  return (
    <div style={{ padding: '2rem', maxWidth: '900px', margin: '0 auto' }}>
      {/* Header with Back Button */}
      <div style={{ marginBottom: '2rem' }}>
        <button 
          onClick={() => navigate('/customers')}
          style={{ padding: '0.5rem 1rem', marginBottom: '1rem', backgroundColor: '#6c757d', color: 'white', border: 'none', borderRadius: '4px', cursor: 'pointer' }}
        >
          ← Back to Customers
        </button>
        
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
          <div>
            <h1 style={{ margin: '0 0 0.5rem 0' }}>{customer.name}</h1>
            {customer.email && <p style={{ margin: '0.25rem 0', color: '#666' }}>📧 {customer.email}</p>}
            {customer.phone && <p style={{ margin: '0.25rem 0', color: '#666' }}>📞 {customer.phone}</p>}
          </div>
          <button 
            onClick={handleLogout}
            style={{ padding: '0.5rem 1rem', backgroundColor: '#dc3545', color: 'white', border: 'none', borderRadius: '4px', cursor: 'pointer' }}
          >
            Logout
          </button>
        </div>
      </div>

      {/* Jobs Section */}
      <div style={{ marginBottom: '2rem', border: '1px solid #dee2e6', borderRadius: '8px', padding: '1.5rem', backgroundColor: '#f8f9fa' }}>
        <h2 style={{ marginTop: 0 }}>📋 Jobs ({jobs.length})</h2>
        {jobs.length === 0 ? (
          <p style={{ color: '#666', fontStyle: 'italic' }}>No jobs scheduled yet</p>
        ) : (
          <div style={{ backgroundColor: 'white', borderRadius: '4px', padding: '1rem' }}>
            {jobs.map((job, index) => (
              <div key={job.id} style={{ 
                marginBottom: index < jobs.length - 1 ? '1.5rem' : 0,
                paddingBottom: index < jobs.length - 1 ? '1.5rem' : 0,
                borderBottom: index < jobs.length - 1 ? '1px solid #eee' : 'none'
              }}>
                <div style={{ marginBottom: '0.5rem' }}>
                  <strong style={{ fontSize: '1.1rem', color: '#333' }}>{job.description}</strong>
                  <span style={{ 
                    marginLeft: '1rem',
                    padding: '0.25rem 0.75rem',
                    borderRadius: '12px',
                    fontSize: '0.85rem',
                    fontWeight: '500',
                    backgroundColor: 
                      job.status === 'completed' ? '#d4edda' :
                      job.status === 'in_progress' ? '#fff3cd' :
                      job.status === 'scheduled' ? '#d1ecf1' :
                      '#f8d7da',
                    color:
                      job.status === 'completed' ? '#155724' :
                      job.status === 'in_progress' ? '#856404' :
                      job.status === 'scheduled' ? '#0c5460' :
                      '#721c24'
                  }}>
                    {job.status.replace('_', ' ').toUpperCase()}
                  </span>
                </div>
                <div style={{ color: '#666', fontSize: '0.9rem', marginBottom: '0.25rem' }}>
                  🗓️ Scheduled: {new Date(job.scheduledAt).toLocaleString('en-US', {
                    weekday: 'short',
                    year: 'numeric',
                    month: 'short',
                    day: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit'
                  })}
                </div>
                
                {/* Job Notes */}
                {jobNotes[job.id] && jobNotes[job.id].length > 0 && (
                  <div style={{ marginTop: '0.75rem', marginLeft: '1rem', padding: '0.75rem', backgroundColor: '#fffbf0', borderLeft: '3px solid #ffc107', borderRadius: '4px' }}>
                    <div style={{ fontSize: '0.85rem', fontWeight: '600', color: '#856404', marginBottom: '0.5rem' }}>
                      💬 Notes:
                    </div>
                    <ul style={{ margin: 0, paddingLeft: '1.25rem' }}>
                      {jobNotes[job.id].map(note => (
                        <li key={note.id} style={{ marginBottom: '0.25rem', fontSize: '0.9rem', color: '#555' }}>
                          {note.text}
                        </li>
                      ))}
                    </ul>
                  </div>
                )}
              </div>
            ))}
          </div>
        )}

        {/* Add Job Form */}
        <div style={{ marginTop: '1.5rem', padding: '1rem', backgroundColor: 'white', borderRadius: '4px', border: '1px solid #dee2e6' }}>
          <h3 style={{ marginTop: 0, fontSize: '1rem', color: '#495057' }}>➕ Add New Job</h3>
          <form onSubmit={handleAddJob}>
            <div style={{ marginBottom: '0.75rem' }}>
              <label style={{ display: 'block', marginBottom: '0.25rem', fontSize: '0.9rem', fontWeight: '500' }}>
                Description
              </label>
              <input
                type="text"
                placeholder="e.g., Install HVAC system"
                value={jobDescription}
                onChange={(e) => setJobDescription(e.target.value)}
                style={{ width: '100%', padding: '0.5rem', fontSize: '1rem', border: '1px solid #ced4da', borderRadius: '4px', boxSizing: 'border-box' }}
              />
            </div>
            <div style={{ marginBottom: '0.75rem' }}>
              <label style={{ display: 'block', marginBottom: '0.25rem', fontSize: '0.9rem', fontWeight: '500' }}>
                Scheduled Date & Time
              </label>
              <input
                type="datetime-local"
                value={jobScheduledAt}
                onChange={(e) => setJobScheduledAt(e.target.value)}
                style={{ width: '100%', padding: '0.5rem', fontSize: '1rem', border: '1px solid #ced4da', borderRadius: '4px', boxSizing: 'border-box' }}
              />
            </div>
            <button type="submit" style={{ padding: '0.5rem 1.5rem', backgroundColor: '#28a745', color: 'white', border: 'none', borderRadius: '4px', cursor: 'pointer', fontWeight: '500' }}>
              Add Job
            </button>
          </form>
        </div>
      </div>

      {/* Notes Section */}
      <div style={{ border: '1px solid #dee2e6', borderRadius: '8px', padding: '1.5rem', backgroundColor: '#f8f9fa' }}>
        <h2 style={{ marginTop: 0 }}>📝 Customer Notes ({customerNotes.length})</h2>
        {customerNotes.length === 0 ? (
          <p style={{ color: '#666', fontStyle: 'italic' }}>No customer notes yet</p>
        ) : (
          <div style={{ backgroundColor: 'white', borderRadius: '4px', padding: '1rem' }}>
            {customerNotes.map((note, index) => (
              <div key={note.id} style={{ 
                marginBottom: index < customerNotes.length - 1 ? '1rem' : 0,
                paddingBottom: index < customerNotes.length - 1 ? '1rem' : 0,
                borderBottom: index < customerNotes.length - 1 ? '1px solid #eee' : 'none'
              }}>
                <div style={{ fontSize: '0.95rem', color: '#333', lineHeight: '1.5' }}>
                  {note.text}
                </div>
                <div style={{ fontSize: '0.8rem', color: '#999', marginTop: '0.25rem' }}>
                  {new Date(note.createdAt).toLocaleString('en-US', {
                    month: 'short',
                    day: 'numeric',
                    year: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit'
                  })}
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Add Note Form */}
        <div style={{ marginTop: '1.5rem', padding: '1rem', backgroundColor: 'white', borderRadius: '4px', border: '1px solid #dee2e6' }}>
          <h3 style={{ marginTop: 0, fontSize: '1rem', color: '#495057' }}>➕ Add New Note</h3>
          <form onSubmit={handleAddNote}>
            <div style={{ marginBottom: '0.75rem' }}>
              <label style={{ display: 'block', marginBottom: '0.25rem', fontSize: '0.9rem', fontWeight: '500' }}>
                Note Text
              </label>
              <textarea
                placeholder="Enter your note here..."
                value={noteText}
                onChange={(e) => setNoteText(e.target.value)}
                style={{ 
                  width: '100%', 
                  padding: '0.5rem', 
                  fontSize: '1rem', 
                  minHeight: '80px', 
                  border: '1px solid #ced4da', 
                  borderRadius: '4px', 
                  fontFamily: 'inherit',
                  boxSizing: 'border-box',
                  resize: 'vertical'
                }}
              />
            </div>
            <div style={{ marginBottom: '0.75rem' }}>
              <label style={{ display: 'block', marginBottom: '0.5rem', fontSize: '0.9rem', fontWeight: '500' }}>
                Attach To:
              </label>
              <div style={{ display: 'flex', gap: '1rem', marginBottom: '0.5rem' }}>
                <label style={{ display: 'flex', alignItems: 'center', cursor: 'pointer' }}>
                  <input
                    type="radio"
                    name="noteTarget"
                    value="customer"
                    checked={noteTarget === 'customer'}
                    onChange={(e) => setNoteTarget(e.target.value)}
                    style={{ marginRight: '0.5rem' }}
                  />
                  Customer
                </label>
                <label style={{ display: 'flex', alignItems: 'center', cursor: 'pointer' }}>
                  <input
                    type="radio"
                    name="noteTarget"
                    value="job"
                    checked={noteTarget === 'job'}
                    onChange={(e) => setNoteTarget(e.target.value)}
                    style={{ marginRight: '0.5rem' }}
                  />
                  Specific Job
                </label>
              </div>
            </div>
            {noteTarget === 'job' && (
              <div style={{ marginBottom: '0.75rem' }}>
                <label style={{ display: 'block', marginBottom: '0.25rem', fontSize: '0.9rem', fontWeight: '500' }}>
                  Select Job
                </label>
                <select
                  value={noteJobId}
                  onChange={(e) => setNoteJobId(e.target.value)}
                  style={{ width: '100%', padding: '0.5rem', fontSize: '1rem', border: '1px solid #ced4da', borderRadius: '4px' }}
                >
                  <option value="">-- Choose a job --</option>
                  {jobs.map(job => (
                    <option key={job.id} value={job.id}>
                      {job.description} ({new Date(job.scheduledAt).toLocaleDateString()})
                    </option>
                  ))}
                </select>
              </div>
            )}
            <button type="submit" style={{ padding: '0.5rem 1.5rem', backgroundColor: '#007bff', color: 'white', border: 'none', borderRadius: '4px', cursor: 'pointer', fontWeight: '500' }}>
              Add Note
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
