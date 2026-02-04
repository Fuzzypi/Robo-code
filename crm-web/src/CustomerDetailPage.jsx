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
    <div style={{ padding: '2rem', maxWidth: '800px' }}>
      {/* Customer Header */}
      <div style={{ marginBottom: '2rem' }}>
        <h1>{customer.name}</h1>
        {customer.email && <p>Email: {customer.email}</p>}
        {customer.phone && <p>Phone: {customer.phone}</p>}
        <button onClick={handleLogout}>Logout</button>
      </div>

      {/* Jobs Section */}
      <div style={{ marginBottom: '2rem', border: '1px solid #ccc', padding: '1rem' }}>
        <h2>Jobs</h2>
        {jobs.length === 0 ? (
          <p>No jobs yet</p>
        ) : (
          <ul>
            {jobs.map(job => (
              <li key={job.id} style={{ marginBottom: '1rem' }}>
                <strong>{job.description}</strong>
                <br />
                Scheduled: {new Date(job.scheduledAt).toLocaleString()}
                <br />
                Status: {job.status}
                
                {/* Job Notes */}
                {jobNotes[job.id] && jobNotes[job.id].length > 0 && (
                  <div style={{ marginLeft: '1rem', marginTop: '0.5rem' }}>
                    <em>Notes:</em>
                    <ul>
                      {jobNotes[job.id].map(note => (
                        <li key={note.id}>{note.text}</li>
                      ))}
                    </ul>
                  </div>
                )}
              </li>
            ))}
          </ul>
        )}

        {/* Add Job Form */}
        <form onSubmit={handleAddJob} style={{ marginTop: '1rem' }}>
          <h3>Add Job</h3>
          <div style={{ marginBottom: '0.5rem' }}>
            <input
              type="text"
              placeholder="Description"
              value={jobDescription}
              onChange={(e) => setJobDescription(e.target.value)}
              style={{ width: '100%', padding: '0.5rem' }}
            />
          </div>
          <div style={{ marginBottom: '0.5rem' }}>
            <input
              type="datetime-local"
              value={jobScheduledAt}
              onChange={(e) => setJobScheduledAt(e.target.value)}
              style={{ width: '100%', padding: '0.5rem' }}
            />
          </div>
          <button type="submit">Add Job</button>
        </form>
      </div>

      {/* Notes Section */}
      <div style={{ border: '1px solid #ccc', padding: '1rem' }}>
        <h2>Customer Notes</h2>
        {customerNotes.length === 0 ? (
          <p>No customer notes yet</p>
        ) : (
          <ul>
            {customerNotes.map(note => (
              <li key={note.id}>{note.text}</li>
            ))}
          </ul>
        )}

        {/* Add Note Form */}
        <form onSubmit={handleAddNote} style={{ marginTop: '1rem' }}>
          <h3>Add Note</h3>
          <div style={{ marginBottom: '0.5rem' }}>
            <textarea
              placeholder="Note text"
              value={noteText}
              onChange={(e) => setNoteText(e.target.value)}
              style={{ width: '100%', padding: '0.5rem', minHeight: '60px' }}
            />
          </div>
          <div style={{ marginBottom: '0.5rem' }}>
            <label>
              Target:
              <select
                value={noteTarget}
                onChange={(e) => setNoteTarget(e.target.value)}
                style={{ marginLeft: '0.5rem', padding: '0.5rem' }}
              >
                <option value="customer">Customer</option>
                <option value="job">Job</option>
              </select>
            </label>
          </div>
          {noteTarget === 'job' && (
            <div style={{ marginBottom: '0.5rem' }}>
              <select
                value={noteJobId}
                onChange={(e) => setNoteJobId(e.target.value)}
                style={{ width: '100%', padding: '0.5rem' }}
              >
                <option value="">Select a job</option>
                {jobs.map(job => (
                  <option key={job.id} value={job.id}>
                    {job.description}
                  </option>
                ))}
              </select>
            </div>
          )}
          <button type="submit">Add Note</button>
        </form>
      </div>
    </div>
  );
}
