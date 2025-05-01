% /---------------------------------\
% |*         Expert System         *|
% |               for               |
% | C A D E N C E   A N A L Y S I S |
% |   Written in SWI-Prolog, 2025   |
% |   from an older code from the   |
% | 1990s (after an Introdoction to |
% | Computer Linguistics seminar in |
% |* English Studies at JGU Mainz) *|
% \---------------------------------/
%
% Components
% ----------
%
% 1. Knowledge Base:        chord_def/4 facts store bass note, figuring, chord name, and function.
% 2. Inference Engine:      analyzes chords and a progression (including deep inference for inversions).
% 3. Explanation Module:    records inference steps (record_explanation/1) and displays them.
% 4. Knowledge Acquisition: add_chord_fact/4 lets user add new chord definitions.
% 5. User Interface:        interactive predicates (start/0, handle_command/1) to interact with the system.
%
% Actually, this is possibly more comments than code, so it should hopefully be self-explanatory.
% If not, the standard modern Prolog primer would be:
%         Patrick Blackburn, Johan Bos, and Kristina Striegnitz:
%         "Learn Prolog Now!", London 2006 (Texts in Computing, 7).

%% DIRECTIVES

:- dynamic(chord_def/4).                    % mark as dynamic (can change during runtime)
:- dynamic(explanation/1).


%% KNOWLEDGE BASE: TRIADS
%
% Only root position chords are stored with figure '5/3'.
% Their spelling follows the standard triads in C major.
% chord_def(BassNote, Inversion, Name, Function)
%   BassNote:  bass tone, equivalent to root tone
%   Inversion: only "5/3" in the KB
%   Name:      what kind of triad
%   Function:  scale function (French style)

chord_def(c, '5/3', 'C major', tonic).
chord_def(d, '5/3', 'D minor', supertonic).
chord_def(e, '5/3', 'E minor', mediant).
chord_def(f, '5/3', 'F major', subdominant).
chord_def(g, '5/3', 'G major', dominant).
chord_def(a, '5/3', 'A minor', submediant).
chord_def(b, '5/3', 'B diminished', leadingtone).


%% KNOWLEDGE BASE: SCALE DEFINITION
%
% The diatonic scale used for inversion calculations.
% Currently, it is defined only for C major.
% It is stored as a list of seven items.

scale([c, d, e, f, g, a, b]).


%% INFERENCE ENGINE: INVERSION CALCULATIONS
%
% For a root position chord ('5/3'), the root is the bass itself.

inversion_root(Bass, '5/3', Bass).


% For a first inversion chord ('6'), the bass tone is the third of a third-stacked triad.
% This, the 'hidden' root is a diatonic third below the bass (i.e. two steps back in the scale).

inversion_root(Bass, '6', Root) :-
    scale(Scale),                           % take the scale,
    nth0(Index, Scale, Bass),               % find the index of the bass tone,
    PreviousIndex is (Index - 2) mod 7,     % calculate the index of the root tone,
    nth0(PreviousIndex, Scale, Root).       % and look up the root tone in the scale list.


% The same for second inversions.
% It is not used in the code, though.

second_inversion_root(Bass, '6/4', Root) :-
    scale(Scale),                           % take the scale,
    nth0(Index, Scale, Bass),               % find the index of the bass tone,
    PreviousIndex is (Index - 4) mod 7,     % calculate the index of the root tone,
    nth0(PreviousIndex, Scale, Root).       % and look up the root tone in the scale list.


%% INFERENCE ENGINE: CHORD ANALYSIS RULES
%
% This implements a direct lookup:
% Prolog will try to unify what it knows directly with the triads as defined above.
% It will first look it up, the document what it has done using a helper rule.

analyze_chord(Bass, Figure, ChordName, Function) :-
    chord_def(Bass, Figure, ChordName, Function),
    record_explanation("Directly found chord: bass ~w with figure ~w is ~w (~w)",
                       [Bass, Figure, ChordName, Function]).


% If no direct match is found and the figure is '6', Prolog will try to apply deep inference.

analyze_chord(Bass, '6', ChordName, Function) :-
    inversion_root(Bass, '6', Root),                    % get the actual root tone first,
    chord_def(Root, '5/3', ChordName, Function),        % then look up, unify, and document
    record_explanation("Deep inference: For bass ~w with figure '6', inferred root ~w leading to ~w (~w)",
                       [Bass, Root, ChordName, Function]).


%% INFERENCE ENGINE: CHORD PROGRESSION ANALYSIS RULES
%
% Analyze a list of chords via recursion.
%    Input  is a list of chord(Bass, Figure) structures.
%    Output is a list of analysis(ChordName, Function) structures.
%
% The recursion uses the list deconstruction (slicing) syntax "[Head | Tail]":
%    1. The HEAD [chord(Bass, Figure) | Rest] takes the first chord in the list.
%    2. analyze_chord/4 is called on that chord.
%    3. The result is stored in analysis(ChordName, Function).
%    4.Recursion continues on the Rest of the list.
%
% The base case handles the empty list as an ending condition.

analyze_progression([], []).                    % Base case: Empty lists result in empty lists.
analyze_progression([chord(Bass, Figure)|Rest],
                    [analysis(ChordName, Function)|AnalysisRest]) :-
    analyze_chord(Bass, Figure, ChordName, Function),   % Analyze first chord,
    analyze_progression(Rest, AnalysisRest).            % then call the recursive process.


%% INFERENCE ENGINE: CADENCE DETECTION
%
% Scans an analyzed progression (list of analysis/2 structures)
%       and identifies cadences by pattern matching on harmonic functions.
%
% Uses append/3 to search for subsequences at any position in the list:
%     append(_, [TargetSequence | _], Analysis)
% ...which means: the sequence occurs somewhere in the Analysis list.

% The first function looks for a Dominant -> Tonic progression.
% append(Left, Pattern, FullList) succeeds if FullList contains Pattern somewhere
%                                             (with anything or nothing before).
% _ is an anonymous variable (similar to _ in Python: "I don't care what's here").

detect_cadence(Analysis, 'Authentic (V-I) Cadence') :-
    append(_, [analysis(_, dominant), analysis(_, tonic)|_], Analysis),
    assertz(explanation("Detected Authentic Cadence (dominant to tonic progression)")).
    

% Same logic, but for Subdominant -> Tonic progressions.

detect_cadence(Analysis, 'Plagal (IV-I) Cadence') :-
    append(_, [analysis(_, subdominant), analysis(_, tonic)|_], Analysis),
    assertz(explanation("Detected Plagal Cadence (subdominant to tonic progression).")).


%% EXPLANATION MODULE
%
% This module provides tools to record, show, and clear explanations
% for each inference step taken by the system.
% Explanations are stored as dynamic facts: explanation(ExplanationText).

% The first function builds a formatted explanation string for later display.
%    Fmt  is a format string, compatible with format/2. It uses ~w placeholders.
%    Args is a list of arguments to be substituted into the format string.
%
% The formatted result is stored as a fact: explanation(ExplanationText).

record_explanation(Fmt, Args) :-
    with_output_to(atom(Explanation), format(Fmt, Args)),
    assertz(explanation(Explanation)).


% The second function prints all recorded explanations to the console.

show_explanations :-
    nl, write('Explanation of Inference:'), nl,
    forall(explanation(Step),
           ( write('- '), write(Step), nl )).


% The third function is a helper, deleting all stored explanation/1 facts.
% This makes room for new explanations before a new analysis is started.

clear_explanations :-
    retractall(explanation(_)).


%% KNOWLEDGE ACQUISITION MODULE
%
% This module adds new facts to the KB. New facts are added at the end of the KB using assertz.
% (In "asserta" and "assertz", a and z actually stand for the German "Anfang" and "zuletzt"!)

add_chord_fact(Bass, Figure, ChordName, Function) :-
    assertz(chord_def(Bass, Figure, ChordName, Function)),
    format("Added chord fact: ~w, ~w -> ~w (%w).~n",
           [Bass, Figure, ChordName, Function]).



%% USER INTERFACE MODULE

start :-
    write('Welcome to the Cadence Analysis Expert System to end all Cadence Analysis Expert Systems!'), nl,
    write('Featuring these spectacular commands: analyze, add, explain, exit'), nl,
    prompt.


prompt :-
    write('Enter command: '),
    read(Command),
    handle_command(Command).


handle_command(analyze) :-
    clear_explanations,
    write('Enter chord progression as a list of chord(Bass, Figure) terms.'), nl,
    write('Example: [chord(c,\'5/3\'), chord(g,\'5/3\')]'), nl,
    read(Progression),
    analyze_progression(Progression, Analysis),
    format('Analysis: ~w~n', [Analysis]),
    ( detect_cadence(Analysis, Cadence) ->
        format('Cadence Detected: ~w~n', [Cadence])
    ; true ),
    prompt.


handle_command(add) :-
    write('Enter new chord fact as: Bass, Figure, ChordName, Function.'), nl,
    read(Bass),
    read(Figure),
    read(ChordName),
    read(Function),
    add_chord_fact(Bass, Figure, ChordName, Function),
    prompt.


handle_command(explain) :-
    show_explanations,
    prompt.


handle_command(exit) :-
    write('Exiting the expert system. You survived!'), nl.


handle_command(_) :-
    write('Unknown command. Please try again. No chance to escape.'), nl,
    prompt.
