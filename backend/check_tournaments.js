const { db } = require('./config/db');
const fs = require('fs');

async function checkTournaments() {
    try {
        const [tournaments] = await db.query('SELECT * FROM tournaments');
        let output = '# Tournament Report\n\n';

        if (tournaments.length === 0) {
            output += 'No tournaments found.\n';
        }

        for (const t of tournaments) {
            output += `## Tournament: ${t.tournament_name} (ID: ${t.id})\n`;
            output += `- Status: **${t.status}**\n`;

            const [matches] = await db.query('SELECT * FROM tournament_matches WHERE tournament_id = ? ORDER BY id ASC', [t.id]);
            const total = matches.length;
            const finished = matches.filter(m => m.status === 'finished' || m.status === 'completed').length;

            output += `- Matches: ${finished}/${total}\n`;

            // Check final match
            // Final match typically has round='final'
            const finalMatch = matches.find(m => m.round === 'final');
            if (finalMatch) {
                output += `- Final Match ID: ${finalMatch.id}, Status: ${finalMatch.status}, Winner: ${finalMatch.winner_id}\n`;
            } else {
                output += `- No 'final' round match found.\n`;
                // List revisions/rounds
                const rounds = [...new Set(matches.map(m => m.round))];
                output += `- Rounds found: ${rounds.join(', ')}\n`;
            }

            output += '\n';
        }

        fs.writeFileSync('tournament_report.md', output);
        console.log('Report written to tournament_report.md');

    } catch (e) {
        console.error(e);
        fs.writeFileSync('tournament_report.md', 'Error: ' + e.message);
    } finally {
        process.exit();
    }
}

checkTournaments();
