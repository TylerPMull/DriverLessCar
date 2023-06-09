function [allData, scenario, sensors] = CurvedSensorData()
%generateSensorData - Returns sensor detections
%    allData = generateSensorData returns sensor detections in a structure
%    with time for an internally defined scenario and sensor suite.
%
%    [allData, scenario, sensors] = generateSensorData optionally returns
%    the drivingScenario and detection generator objects.

% Generated by MATLAB(R) 9.14 (R2023a) and Automated Driving Toolbox 3.7 (R2023a).
% Generated on: 11-May-2023 02:13:47

% Create the drivingScenario object and ego car
[scenario, egoVehicle] = createDrivingScenario;

% Create all the sensors
[sensors, numSensors] = createSensors(scenario);

allData = struct('Time', {}, 'ActorPoses', {}, 'ObjectDetections', {}, 'LaneDetections', {}, 'PointClouds', {}, 'INSMeasurements', {});
running = true;
while running

    % Generate the target poses of all actors relative to the ego vehicle
    poses = targetPoses(egoVehicle);
    time  = scenario.SimulationTime;

    objectDetections = {};
    laneDetections   = [];
    ptClouds = {};
    insMeas = {};
    isValidTime = false(1, numSensors);

    % Generate detections for each sensor
    for sensorIndex = 1:numSensors
        sensor = sensors{sensorIndex};
        [objectDets, isValidTime(sensorIndex)] = sensor(poses, time);
        numObjects = length(objectDets);
        objectDetections = [objectDetections; objectDets(1:numObjects)]; %#ok<AGROW>
    end

    % Aggregate all detections into a structure for later use
    if any(isValidTime)
        allData(end + 1) = struct( ...
            'Time',       scenario.SimulationTime, ...
            'ActorPoses', actorPoses(scenario), ...
            'ObjectDetections', {objectDetections}, ...
            'LaneDetections', {laneDetections}, ...
            'PointClouds',   {ptClouds}, ... %#ok<AGROW>
            'INSMeasurements',   {insMeas}); %#ok<AGROW>
    end

    % Advance the scenario one time step and exit the loop if the scenario is complete
    running = advance(scenario);
end

% Restart the driving scenario to return the actors to their initial positions.
restart(scenario);

% Release all the sensor objects so they can be used again.
for sensorIndex = 1:numSensors
    release(sensors{sensorIndex});
end

%%%%%%%%%%%%%%%%%%%%
% Helper functions %
%%%%%%%%%%%%%%%%%%%%

% Units used in createSensors and createDrivingScenario
% Distance/Position - meters
% Speed             - meters/second
% Angles            - degrees
% RCS Pattern       - dBsm

function [sensors, numSensors] = createSensors(scenario)
% createSensors Returns all sensor objects to generate detections

% Assign into each sensor the physical and radar profiles for all actors
profiles = actorProfiles(scenario);
sensors{1} = visionDetectionGenerator('SensorIndex', 1, ...
    'SensorLocation', [1.9 0], ...
    'DetectorOutput', 'Objects only', ...
    'ActorProfiles', profiles);
sensors{2} = drivingRadarDataGenerator('SensorIndex', 2, ...
    'MountingLocation', [2.8 0.9 0.2], ...
    'MountingAngles', [41.2801228276758 0 0], ...
    'RangeLimits', [0 50], ...
    'TargetReportFormat', 'Detections', ...
    'FieldOfView', [90 5], ...
    'Profiles', profiles);
sensors{3} = drivingRadarDataGenerator('SensorIndex', 3, ...
    'MountingLocation', [2.8 -0.9 0.2], ...
    'MountingAngles', [-41.4647539271478 0 0], ...
    'RangeLimits', [0 50], ...
    'TargetReportFormat', 'Detections', ...
    'FieldOfView', [90 5], ...
    'Profiles', profiles);
numSensors = 3;

function [scenario, egoVehicle] = createDrivingScenario
% createDrivingScenario Returns the drivingScenario defined in the Designer

% Construct a drivingScenario object.
scenario = drivingScenario;

% Add all road segments
roadCenters = [78 19.6 0;
    31 5 0;
    27.7 -17.5 0;
    -16.3 -9.8 0];
marking = [laneMarking('Solid', 'Color', [0.98 0.86 0.36])
    laneMarking('DoubleSolid')
    laneMarking('Solid')];
laneSpecification = lanespec(2, 'Marking', marking);
road(scenario, roadCenters, 'Lanes', laneSpecification, 'Name', 'Road');

% Add the ego vehicle
egoVehicle = vehicle(scenario, ...
    'ClassID', 1, ...
    'Position', [73.9 21.8 0], ...
    'Mesh', driving.scenario.carMesh, ...
    'Name', 'Car');
waypoints = [73.9 21.8 0;
    62.5 23.5 0;
    53.4 23.8 0;
    44.3 21.2 0;
    37.2 17 0;
    30.8 10.3 0;
    28.5 2.4 0;
    27.8 -7.3 0;
    26.3 -15.7 0;
    20.9 -21.9 0;
    13.9 -24.5 0;
    4.9 -23 0;
    -2.5 -19.1 0;
    -9.3 -13.9 0;
    -13.9 -9.1 0];
speed = [30;30;30;30;30;30;30;30;30;30;30;30;30;30;30];
trajectory(egoVehicle, waypoints, speed);

% Add the non-ego actors
car1 = vehicle(scenario, ...
    'ClassID', 1, ...
    'Position', [-16.6529061171245 -12.8162961532673 0], ...
    'Mesh', driving.scenario.carMesh, ...
    'Name', 'Car1');
waypoints = [-16.6529061171245 -12.8162961532673 0;
    -12.5 -15.6 0;
    -5.8 -21.1 0;
    2.9 -26 0;
    11.8 -28.2 0;
    20.8 -26.6 0;
    27.1 -21.9 0;
    31 -15.6 0;
    32 -5.5 0;
    33.4 5.9 0;
    38.1 12.6 0;
    47.2 18.1 0;
    57.7 20.2 0;
    67.3 19.7 0;
    76.3 18.3 0];
speed = [30;30;30;30;30;30;30;30;30;30;30;30;30;30;30];
trajectory(car1, waypoints, speed);

