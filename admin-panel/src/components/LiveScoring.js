import React, { useState, useEffect, useCallback } from 'react';
import { adminAPI } from '../services/api';

const LiveScoring = ({ matchId, onBack, onToast }) => {
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [actionLoading, setActionLoading] = useState(false);
    const [showWicketModal, setShowWicketModal] = useState(false);
    const [showPlayerModal, setShowPlayerModal] = useState({ show: false, role: '' });
    const [wicketData, setWicketData] = useState({ type: 'bowled', outPlayerId: null });

    const fetchData = useCallback(async () => {
        try {
            const response = await adminAPI.getLiveScoreView(matchId);
            setData(response.data);
            if (loading) setLoading(false);
        } catch (err) {
            console.error('Error fetching live score:', err);
            setError(err.userMessage || 'Failed to fetch live score data');
            if (loading) setLoading(false);
        }
    }, [matchId, loading]);

    useEffect(() => {
        fetchData();
        const interval = setInterval(fetchData, 5000);
        return () => clearInterval(interval);
    }, [fetchData]);

    const handleAction = async (actionFn, ...args) => {
        if (actionLoading) return;
        setActionLoading(true);
        try {
            await actionFn(...args);
            await fetchData();
            onToast('Success', 'success');
        } catch (err) {
            console.error('Action failed:', err);
            onToast(err.userMessage || 'Action failed', 'error');
        } finally {
            setActionLoading(false);
        }
    };

    const recordBall = (runs, extras = null, wicketType = null, outPlayerId = null) => {
        if (!data || !data.innings) return;
        const activeInning = data.innings.find(i => i.status === 'in_progress');
        if (!activeInning) return;

        handleAction(adminAPI.addBall, {
            match_id: matchId,
            inning_id: activeInning.id,
            over_number: activeInning.overs,
            ball_number: (activeInning.legal_balls % 6) + 1,
            runs: runs + (extras === 'wide' || extras === 'no-ball' ? 1 : 0),
            extras: extras,
            wicket_type: wicketType,
            out_player_id: outPlayerId
        });
    };

    const setPlayer = (playerId, role) => {
        if (!data || !data.innings) return;
        const activeInning = data.innings.find(i => i.status === 'in_progress');
        if (!activeInning) return;

        handleAction(adminAPI.setNewBatter, {
            inning_id: activeInning.id,
            new_batter_id: playerId,
            role: role
        });
        setShowPlayerModal({ show: false, role: '' });
    };

    const startNextInning = () => {
        if (!data) return;
        const nextNum = (data.innings?.length || 0) + 1;

        // Swap teams logic
        let batId, bowlId;
        if (nextNum === 1) {
            batId = data.team1_id;
            bowlId = data.team2_id;
        } else {
            const prevInning = data.innings[nextNum - 2];
            batId = prevInning.bowling_team_id;
            bowlId = prevInning.batting_team_id;
        }

        handleAction(adminAPI.startInnings, {
            match_id: matchId,
            batting_team_id: batId,
            bowling_team_id: bowlId,
            inning_number: nextNum
        });
    };

    const handleUndo = () => {
        if (!data || !data.innings) return;
        const activeInning = data.innings.find(i => i.status === 'in_progress') || data.innings[data.innings.length - 1];
        if (!activeInning) return;

        handleAction(adminAPI.undoLastBall, {
            match_id: matchId,
            inning_id: activeInning.id
        });
    };

    if (loading) return <div className="p-8 text-center text-gray-500">Loading Scoring Interface...</div>;
    if (error) return <div className="p-8 text-center text-red-500">{error}</div>;

    // Use the latest inning (especially important if multiple are 'in_progress' due to old bugs)
    const activeInning = [...(data.innings || [])].reverse().find(i => i.status === 'in_progress');
    const isCompleted = data.status === 'completed';

    const renderScoringButtons = () => (
        <div className="grid grid-cols-4 gap-4 mb-8">
            {[0, 1, 2, 3, 4, 6].map(run => (
                <button
                    key={run}
                    onClick={() => recordBall(run)}
                    disabled={actionLoading}
                    className="h-16 bg-white border-2 border-indigo-100 rounded-xl font-bold text-2xl text-indigo-900 hover:bg-indigo-50 hover:border-indigo-200 transition-all shadow-sm active:scale-95 flex items-center justify-center"
                >
                    {run}
                </button>
            ))}
            <button
                onClick={() => recordBall(0, 'wide')}
                disabled={actionLoading}
                className="h-16 bg-yellow-50 border-2 border-yellow-200 rounded-xl font-bold text-xl text-yellow-800 hover:bg-yellow-100 transition-all shadow-sm active:scale-95"
            >
                WD
            </button>
            <button
                onClick={() => recordBall(0, 'no-ball')}
                disabled={actionLoading}
                className="h-16 bg-yellow-50 border-2 border-yellow-200 rounded-xl font-bold text-xl text-yellow-800 hover:bg-yellow-100 transition-all shadow-sm active:scale-95"
            >
                NB
            </button>
            <button
                onClick={() => setShowWicketModal(true)}
                disabled={actionLoading}
                className="h-16 bg-red-50 border-2 border-red-200 rounded-xl font-bold text-xl text-red-800 hover:bg-red-100 transition-all shadow-sm active:scale-95 col-span-2"
            >
                WICKET
            </button>
            <button
                onClick={() => recordBall(0, 'bye')}
                disabled={actionLoading}
                className="h-16 bg-gray-50 border-2 border-gray-200 rounded-xl font-bold text-xl text-gray-800 hover:bg-gray-100 transition-all shadow-sm active:scale-95"
            >
                Bye
            </button>
            <button
                onClick={() => recordBall(0, 'leg-bye')}
                disabled={actionLoading}
                className="h-16 bg-gray-50 border-2 border-gray-200 rounded-xl font-bold text-xl text-gray-800 hover:bg-gray-100 transition-all shadow-sm active:scale-95"
            >
                Leg Bye
            </button>
        </div>
    );

    const renderPlayerSelectors = () => {
        const { currentContext = {} } = data;
        const striker = currentContext.batsmen?.[0];
        const nonStriker = currentContext.batsmen?.[1];
        const bowler = currentContext.bowler;

        return (
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
                <div
                    onClick={() => setShowPlayerModal({ show: true, role: 'striker' })}
                    className={`p-4 rounded-xl border-2 transition-all cursor-pointer shadow-sm ${striker ? 'bg-green-50 border-green-200' : 'bg-white border-dashed border-gray-300'}`}
                >
                    <span className="text-[10px] uppercase font-black text-green-600 tracking-wider">Striker</span>
                    <h4 className="font-bold text-gray-900 truncate">{striker ? striker.player_name : 'Select Striker'}</h4>
                    {striker && <p className="text-sm font-medium text-green-700">{striker.runs} ({striker.balls_faced})</p>}
                </div>
                <div
                    onClick={() => setShowPlayerModal({ show: true, role: 'non_striker' })}
                    className={`p-4 rounded-xl border-2 transition-all cursor-pointer shadow-sm ${nonStriker ? 'bg-blue-50 border-blue-200' : 'bg-white border-dashed border-gray-300'}`}
                >
                    <span className="text-[10px] uppercase font-black text-blue-600 tracking-wider">Non-Striker</span>
                    <h4 className="font-bold text-gray-900 truncate">{nonStriker ? nonStriker.player_name : 'Select Non-Striker'}</h4>
                    {nonStriker && <p className="text-sm font-medium text-blue-700">{nonStriker.runs} ({nonStriker.balls_faced})</p>}
                </div>
                <div
                    onClick={() => setShowPlayerModal({ show: true, role: 'bowler' })}
                    className={`p-4 rounded-xl border-2 transition-all cursor-pointer shadow-sm ${bowler ? 'bg-red-50 border-red-200' : 'bg-white border-dashed border-gray-300'}`}
                >
                    <span className="text-[10px] uppercase font-black text-red-600 tracking-wider">Bowler</span>
                    <h4 className="font-bold text-gray-900 truncate">{bowler ? bowler.player_name : 'Select Bowler'}</h4>
                    {bowler && <p className="text-sm font-medium text-red-700">{bowler.wickets}-{bowler.runs_conceded} ({Math.floor(bowler.balls_bowled / 6)}.{bowler.balls_bowled % 6})</p>}
                </div>
            </div>
        );
    };

    return (
        <div className="max-w-4xl mx-auto space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
            {/* Header */}
            <div className="bg-white p-4 rounded-xl shadow-sm border border-gray-100 flex justify-between items-center bg-gradient-to-r from-white to-gray-50">
                <button onClick={onBack} className="flex items-center text-gray-600 hover:text-indigo-600 font-medium transition group">
                    <svg className="w-5 h-5 mr-1 transform group-hover:-translate-x-1 transition" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" /></svg>
                    Matches
                </button>
                <div className="flex items-center space-x-3">
                    {!isCompleted && activeInning && <button onClick={handleUndo} className="px-4 py-2 text-sm font-bold text-gray-500 hover:text-red-500 border border-gray-200 rounded-lg hover:border-red-100 hover:bg-red-50 transition">UNDO LAST BALL</button>}
                    {!isCompleted && !activeInning && <button onClick={startNextInning} className="px-6 py-2 bg-indigo-600 text-white rounded-lg font-bold shadow-lg shadow-indigo-200 hover:bg-indigo-700 hover:-translate-y-0.5 transition">START INNINGS</button>}
                    {isCompleted && <span className="px-4 py-2 bg-gray-100 text-gray-600 rounded-lg font-bold">MATCH COMPLETED</span>}
                </div>
            </div>

            {activeInning && (
                <>
                    {/* Live Score */}
                    <div className="bg-indigo-900 text-white p-8 rounded-2xl shadow-xl border-b-4 border-indigo-700 overflow-hidden relative">
                        <div className="absolute top-0 right-0 w-64 h-64 bg-indigo-800/30 rounded-full -mr-32 -mt-32 blur-3xl"></div>
                        <div className="relative z-10 flex flex-col md:flex-row justify-between items-center text-center md:text-left gap-6">
                            <div>
                                <h2 className="text-indigo-200 text-xs font-black uppercase tracking-[0.2em] mb-2">{activeInning.batting_team_name} BATTING</h2>
                                <div className="flex items-baseline">
                                    <span className="text-7xl font-black tabular-nums">{activeInning.runs}/{activeInning.wickets}</span>
                                    <span className="ml-4 text-2xl text-indigo-300 font-bold">({activeInning.overs_decimal})</span>
                                </div>
                            </div>
                            <div className="flex flex-col items-center md:items-end">
                                <div className="grid grid-cols-2 md:grid-cols-3 gap-8 text-center bg-indigo-800/50 p-6 rounded-2xl border border-indigo-700/50 backdrop-blur-sm">
                                    <div>
                                        <p className="text-indigo-300 text-[10px] font-black uppercase tracking-widest mb-1">CRR</p>
                                        <p className="text-2xl font-black">{data.stats?.crr || '0.00'}</p>
                                    </div>
                                    {activeInning.inning_number === 2 && data.target_score && (
                                        <div>
                                            <p className="text-indigo-300 text-[10px] font-black uppercase tracking-widest mb-1">Target</p>
                                            <p className="text-2xl font-black text-yellow-400">{data.target_score}</p>
                                        </div>
                                    )}
                                    {activeInning.inning_number === 2 && data.target_score && (
                                        <div>
                                            <p className="text-indigo-300 text-[10px] font-black uppercase tracking-widest mb-1">RRR</p>
                                            <p className="text-2xl font-black text-yellow-400">{data.stats?.rrr || '0.00'}</p>
                                        </div>
                                    )}
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Main UI */}
                    <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                        <div className="lg:col-span-2">
                            {renderPlayerSelectors()}
                            {renderScoringButtons()}
                        </div>
                        <div>
                            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden h-full flex flex-col">
                                <div className="px-5 py-4 bg-gray-50 border-b border-gray-100">
                                    <h3 className="font-black text-gray-800 text-sm tracking-widest uppercase">Timeline</h3>
                                </div>
                                <div className="p-6 overflow-y-auto flex-1 bg-gray-50/20">
                                    <div className="flex flex-wrap gap-3">
                                        {(data.currentContext?.recentBalls || []).map((ball, i) => (
                                            <div key={i} className={`w-10 h-10 rounded-full flex items-center justify-center font-black text-sm shadow-sm border-2 ${ball.wicket_type ? 'bg-red-600 border-red-700 text-white' :
                                                ball.runs >= 4 ? 'bg-indigo-600 border-indigo-700 text-white' :
                                                    ball.extras ? 'bg-yellow-400 border-yellow-500 text-yellow-900' :
                                                        'bg-white border-gray-200 text-gray-800'
                                                }`}>
                                                {ball.wicket_type ? 'W' : (ball.extras && ball.runs === 0 ? 'Ex' : ball.runs)}
                                            </div>
                                        ))}
                                        {(!data.currentContext?.recentBalls || data.currentContext.recentBalls.length === 0) && (
                                            <div className="py-12 w-full text-center text-gray-400 italic text-sm">New over beginning...</div>
                                        )}
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </>
            )}

            {!activeInning && !isCompleted && (
                <div className="bg-white p-12 rounded-2xl shadow-sm border-2 border-dashed border-gray-200 text-center space-y-4">
                    <div className="w-20 h-20 bg-indigo-50 rounded-full flex items-center justify-center mx-auto">
                        <svg className="w-10 h-10 text-indigo-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 8v4l3 2m6-2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                    </div>
                    <h3 className="text-2xl font-black text-gray-900">Wait for Next Innings</h3>
                    <p className="text-gray-500 max-w-sm mx-auto">The current innings has concluded. Click the button below to start the next innings.</p>
                    <button onClick={startNextInning} className="px-10 py-4 bg-indigo-600 text-white rounded-xl font-black shadow-xl shadow-indigo-200 hover:bg-indigo-700 transition transform hover:-translate-y-1 active:scale-95">START NEXT INNINGS</button>
                </div>
            )}

            {/* Modals Interface */}
            {showWicketModal && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-300">
                    <div className="bg-white rounded-3xl p-8 max-w-sm w-full shadow-2xl animate-in zoom-in-95 duration-300">
                        <h3 className="text-2xl font-black text-gray-900 mb-6 flex items-center">
                            <span className="w-10 h-10 bg-red-100 text-red-600 rounded-full flex items-center justify-center mr-3">W</span>
                            Dismissal Details
                        </h3>

                        <div className="space-y-6">
                            <div>
                                <label className="block text-[10px] font-black text-gray-400 uppercase tracking-widest mb-2">Type of Wicket</label>
                                <select
                                    className="w-full p-4 bg-gray-50 border-2 border-gray-100 rounded-xl font-bold focus:border-red-200 outline-none transition"
                                    value={wicketData.type}
                                    onChange={(e) => setWicketData({ ...wicketData, type: e.target.value })}
                                >
                                    {['bowled', 'caught', 'lbw', 'run_out', 'stumped', 'hit_wicket', 'retired_hurt'].map(t => (
                                        <option key={t} value={t}>{t.replace('_', ' ').toUpperCase()}</option>
                                    ))}
                                </select>
                            </div>

                            <div>
                                <label className="block text-[10px] font-black text-gray-400 uppercase tracking-widest mb-2">Player Out</label>
                                <div className="grid grid-cols-1 gap-3">
                                    {(data.currentContext?.batsmen || []).map(p => (
                                        <button
                                            key={p.player_id}
                                            onClick={() => setWicketData({ ...wicketData, outPlayerId: p.player_id })}
                                            className={`p-4 rounded-xl border-2 font-bold text-left transition ${wicketData.outPlayerId === p.player_id ? 'bg-red-50 border-red-200 text-red-700' : 'bg-gray-50 border-transparent text-gray-600 hover:bg-gray-100'}`}
                                        >
                                            {p.player_name}
                                        </button>
                                    ))}
                                </div>
                            </div>
                        </div>

                        <div className="flex gap-4 mt-8">
                            <button onClick={() => setShowWicketModal(false)} className="flex-1 p-4 bg-gray-100 text-gray-600 font-bold rounded-xl hover:bg-gray-200 transition">CANCEL</button>
                            <button
                                onClick={() => {
                                    recordBall(0, null, wicketData.type, wicketData.outPlayerId);
                                    setShowWicketModal(false);
                                }}
                                disabled={!wicketData.outPlayerId}
                                className="flex-1 p-4 bg-red-600 text-white font-bold rounded-xl shadow-lg shadow-red-200 hover:bg-red-700 disabled:opacity-50 transition"
                            >
                                CONFIRM
                            </button>
                        </div>
                    </div>
                </div>
            )}

            {showPlayerModal.show && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-300">
                    <div className="bg-white rounded-3xl p-8 max-w-md w-full shadow-2xl animate-in zoom-in-95 duration-300">
                        <h3 className="text-2xl font-black text-gray-900 mb-6">Select {showPlayerModal.role.toUpperCase()}</h3>
                        <div className="max-h-96 overflow-y-auto space-y-1 pr-2 custom-scrollbar">
                            {(
                                // If role is bowler, show bowling team players
                                // If role is striker/non_striker, show batting team players
                                (showPlayerModal.role === 'bowler'
                                    ? (activeInning.bowling_team_id === data.team1_id ? data.team1_players : data.team2_players)
                                    : (activeInning.batting_team_id === data.team1_id ? data.team1_players : data.team2_players)
                                ) || []
                            ).map(p => (
                                <button
                                    key={p.id}
                                    onClick={() => setPlayer(p.id, showPlayerModal.role)}
                                    className="w-full p-4 text-left hover:bg-indigo-50 rounded-xl transition font-bold text-gray-700 hover:text-indigo-600 flex items-center"
                                >
                                    <div className="w-8 h-8 bg-gray-100 rounded-full flex items-center justify-center mr-3 text-xs text-gray-400">#</div>
                                    {p.player_name}
                                </button>
                            ))}
                        </div>
                        <button onClick={() => setShowPlayerModal({ show: false, role: '' })} className="w-full mt-6 p-4 bg-gray-100 text-gray-600 font-bold rounded-xl hover:bg-gray-200 transition">CANCEL</button>
                    </div>
                </div>
            )}
        </div>
    );
};

export default LiveScoring;
