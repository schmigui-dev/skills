import { Hono } from 'hono';
import { db } from '../db';

export const app = new Hono();

export async function updateStatus(id: string, status: 'draft' | 'accepted') {
  await db.query('UPDATE proposals SET status = $1 WHERE id = $2', [status, id]);
}

app.post('/quotes/:id/accept', async (c) => {
  await updateStatus(c.req.param('id'), 'accepted');
  return c.json({ ok: true });
});
