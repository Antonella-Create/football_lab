const fs = require('fs');
const path = require('path');
const csv = require('csv-parser');
const mysql = require('mysql2/promise');
require('dotenv').config();

async function getOrCreateEntity(connection, tableName, columnName, entityValue) {
    const [rows] = await connection.execute(
        `SELECT ${columnName}_id FROM ${tableName} WHERE ${columnName}_name = ?`,
        [entityValue]
    );
    if (rows.length > 0) {
        return rows[0][`${columnName}_id`];
    }
    const [result] = await connection.execute(
        `INSERT INTO ${tableName} (${columnName}_name) VALUES (?)`,
        [entityValue]
    );
    return result.insertId;
}

async function executeLoadingProcess() {
    const dbConfig = {
        host: process.env.DB_HOST,
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        database: process.env.DB_NAME,
        port: Number(process.env.DB_PORT)
    };

    const connection = await mysql.createConnection(dbConfig);
    const seasonMap = new Map();
    const teamMap = new Map();
    let insertedRows = 0;

    try {
        await connection.beginTransaction();
        const csvFilePath = path.join(__dirname, process.env.CSV_FILENAME || 'football_matches.csv');
        
        if (!fs.existsSync(csvFilePath)) {
            throw new Error('Source CSV file does not exist.');
        }

        const readStream = fs.createReadStream(csvFilePath).pipe(csv());

        for await (const row of readStream) {
            const seasonName = row.season ? row.season.trim() : null;
            const homeTeam = row.home_team ? row.home_team.trim() : null;
            const awayTeam = row.away_team ? row.away_team.trim() : null;

            if (!seasonName || !homeTeam || !awayTeam) {
                throw new Error('Invalid row data encountered: missing required names.');
            }

            if (!seasonMap.has(seasonName)) {
                const seasonId = await getOrCreateEntity(connection, 'season', 'season', seasonName);
                seasonMap.set(seasonName, seasonId);
            }

            if (!teamMap.has(homeTeam)) {
                const teamId = await getOrCreateEntity(connection, 'team', 'team', homeTeam);
                teamMap.set(homeTeam, teamId);
            }

            if (!teamMap.has(awayTeam)) {
                const teamId = await getOrCreateEntity(connection, 'team', 'team', awayTeam);
                teamMap.set(awayTeam, teamId);
            }

            const seasonId = seasonMap.get(seasonName);
            const homeTeamId = teamMap.get(homeTeam);
            const awayTeamId = teamMap.get(awayTeam);

            const homeGoals = parseInt(row.goal_home_ft, 10);
            const awayGoals = parseInt(row.goal_away_ft, 10);
            const homePossession = parseFloat(row.home_possession);
            const awayPossession = parseFloat(row.away_possession);
            const homeShotsOnTarget = parseInt(row.home_shots_on_target, 10);
            const awayShotsOnTarget = parseInt(row.away_shots_on_target, 10);
            const homeRedCards = parseInt(row.home_red_cards, 10);
            const awayRedCards = parseInt(row.away_red_cards, 10);

            if (isNaN(homeGoals) || isNaN(awayGoals) || isNaN(homePossession) || isNaN(awayPossession)) {
                throw new Error(`Invalid numeric conversion in row for match between ${homeTeam} and ${awayTeam}.`);
            }

            await connection.execute(
                `INSERT INTO game (
                    season_id, home_team_id, away_team_id, home_goals, away_goals,
                    home_possession, away_possession, home_shots_on_target, away_shots_on_target,
                    home_red_cards, away_red_cards
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
                [
                    seasonId, homeTeamId, awayTeamId, homeGoals, awayGoals,
                    homePossession, awayPossession, homeShotsOnTarget, awayShotsOnTarget,
                    homeRedCards, awayRedCards
                ]
            );
            insertedRows++;
        }

        await connection.commit();
        console.log(`Massive load finished successfully. Total inserted rows: ${insertedRows}`);
    } catch (errorException) {
        await connection.rollback();
        console.error('Failure in massive load:', errorException.message);
        throw errorException;
    } finally {
        await connection.end();
    }
}

executeLoadingProcess();
