
% *********** Anomaly Detection for Marketplaces *************
% Author:   Saeid.S.Nobakht
% Email:    sd.nobakht@gmail.com
% Version:  0.0.1
% Description:
%   Extract stocks which have suspicious behaviors,
%   according to their purchase time.
% ************************************************************

%% ============== Prepare Workspace =============
clear all;
close all;
clc;


%% ================ Configuratons ===============
INPUT_FILE = 'datasets/purchases_list_v1.csv';  % dataset file path
HIST_OUTPUT_DIR = 'figures/hists/';             % results directory
CLUSTERING_RESULT_DIR = 'figures/clustering/';  % results directory
FEATURES_FIGURES_DIR = 'figures/features/';     % results directory
ORIGIN_YEAR = 2010;                             % only for better describing
ONLY_SAVE_FIGURE = 1;                           % don't show, only save
SKIP_STEP_1 = 1;                                % skip first step calculations
STEP_1_DUMP_FILE = 'ws_saved_files/step_1.mat';             % dump of step 1 workspace
FEATURES_DUMP_FILE = 'ws_saved_files/features.mat';         % dump of feature vectors
EXTRACT_FEATURES = 0;                                       % extract features again or not
CLUSTERING_ANALYSIS = 0;                                    % do clustering analysis
CLUSTERS_DUMP_FILE = 'ws_saved_files/best_clusters.mat';    % dump of best clusters
REGENERATE_BEST_CLUSTERS = 1;                               % regenerate the best clusters
NO_SUSPICIOUS_SAMPLE = 30;                                  % this used to fit model

%% ============ Initialize Variables ============
%cnt = 0;



%% =============== Loading Dataset ==============
fprintf('Loading Dataset...');
data = csvread(INPUT_FILE);
fprintf('Done\n');


%% ================ First Attempt ================
% ---------------- Data Investigation------------
min_time = min(data(:,2))/86400; % get min time according to days from orgin
max_time = max(data(:,2))/86400; % get max time according to days from orgin
%min_date = datestr(min(data(:,2))/86400 + datenum(2010,1,1));
%max_date = datestr(max(data(:,2))/86400 + datenum(2010,1,1));
%min_date = datevec(min(data(:,2))/86400 + datenum(ORIGIN_YEAR,1,1));
%max_date = datevec(max(data(:,2))/86400 + datenum(ORIGIN_YEAR,1,1));
min_date = datevec(min(data(:,2))/86400);
max_date = datevec(max(data(:,2))/86400);
fprintf('Datasets Time Range: %4.2f Days\n', max_time - min_time);

[counts, centers]=hist(data(:,1),unique(data(:,1)));
counts = counts';
no_apps = size(counts, 1);
fprintf('Number of Apps: %d\n', no_apps);

percent_under_the_mean = size(counts(counts<mean(counts)),1)/no_apps;
fprintf('Under the mean purchases: %2.3f%%\n', percent_under_the_mean*100);

percent_with_one_purchase = size(counts(counts<2),1)/no_apps;
fprintf('Apps with only 1 purchase: %2.3f%%\n', percent_with_one_purchase*100);

apps_purchase_count = [centers, counts];
filtered_items_index = find(apps_purchase_count(:,2)>1);
apps_more_than_one_purchase = apps_purchase_count(filtered_items_index, :);

no_top_apps = 20;
no_bins = 40;
top_k_apps_info = get_max_k(apps_more_than_one_purchase, no_top_apps, 2);
if SKIP_STEP_1
    load(STEP_1_DUMP_FILE);
else
    for i=1:no_top_apps
        if ONLY_SAVE_FIGURE
            h=figure('Visible','off');
        else
            h = figure;
        end    
        histogram_data = data(find(data(:,1)==top_k_apps_info(i,1)), :);
        hist(sqrt(histogram_data(:,2)) , no_bins); % histogram on time
        ylabel('Number of Purchases');
        xlabel('Time (Seconds)');
        title_str = sprintf('App Info\nid=%d, purchases=%d, rank=%d', histogram_data(i,1), top_k_apps_info(i,2), i);
        title(title_str);
        file_name = sprintf('%s%d_%d_%d.png', HIST_OUTPUT_DIR, top_k_apps_info(i,1), top_k_apps_info(i,2), i);
        saveas(h, file_name);
        close(h);
    end
    save(STEP_1_DUMP_FILE);
end


%% ================ Second Attempt ================
% --------- Feature Design & Extraction ----------
fprintf('Extracting New Features...');

[counts, centers]=hist(data(:,1),unique(data(:,1)));
counts = counts';
apps_purchase_count = [centers, counts];
filtered_items_index = find(apps_purchase_count(:,2)>mean(apps_purchase_count(:,2)));
apps_more_than_mean_purchase = apps_purchase_count(filtered_items_index, :);

no_top_apps = size(apps_more_than_mean_purchase, 1);
top_k_apps_info = get_max_k(apps_more_than_mean_purchase, no_top_apps, 2);
if EXTRACT_FEATURES
    apps_metrics = zeros(no_top_apps, 7);
    for i=1:no_top_apps    
        histogram_data = data(find(data(:,1)==top_k_apps_info(i,1)), :);
        min_app_date = datevec(min(histogram_data(:,2))/86400 + datenum(2010,1,1));
        max_app_date = datevec(max(histogram_data(:,2))/86400 + datenum(2010,1,1));
        app_time_range_start = min_app_date;
        app_time_range_start(1,4) = 0;
        app_time_range_start(1,5) = 0;
        app_time_range_start(1,6) = 0;    
        app_time_range_start = datetime(app_time_range_start);
        app_time_range_start = posixtime(app_time_range_start);
        app_time_range_end = max_app_date;
        app_time_range_end(1,4) = 23;
        app_time_range_end(1,5) = 59;
        app_time_range_end(1,6) = 59;
        app_time_range_end = datetime(app_time_range_end);
        app_time_range_end = posixtime(app_time_range_end);
        no_bins = ceil((app_time_range_end - app_time_range_start)/(8*3600));
        [counts, centers] = hist(histogram_data(:,2) , no_bins); % histogram on time
        index_vector = 1:size(counts,2);
        hist_data_per_hour = [index_vector', counts'];
        purchases_on_midnight = hist_data_per_hour(find(rem(hist_data_per_hour(:,1), 3)==1), 2);
        purchases_on_day_or_night = hist_data_per_hour(find(rem(hist_data_per_hour(:,1), 3)~=1), 2);
        apps_metrics(i,1) = mean(purchases_on_day_or_night);    % mean of daily purchases 
        apps_metrics(i,2) = var(purchases_on_day_or_night);     % var of daily purchases
        apps_metrics(i,3) = mean(purchases_on_midnight);    % mean of nightly purchases 
        apps_metrics(i,4) = var(purchases_on_midnight);     % var of nightly purchases    
        apps_metrics(i,5) = sum(hist_data_per_hour(:,2))/sum(purchases_on_midnight);
        apps_metrics(i,6) = sum(purchases_on_midnight>0)/size(purchases_on_midnight,1);   % fraction of nightly purchases to all days
        apps_metrics(i,7) = top_k_apps_info(i,1);   % app id
    end
    save(FEATURES_DUMP_FILE, 'apps_metrics');
else
    load(FEATURES_DUMP_FILE);
end

fprintf('Done\n');

%% ================= Third Attempt ================
if CLUSTERING_ANALYSIS
    % --------- Clustering ----------
    fprintf('Apply Clustering\n');
    fprintf('Apply K-Means (K=2, dist=CityBlock)\n');
    f = figure;
    cidx = kmeans(apps_metrics(:,1:6),2,'distance','cityblock');
    cluster_1_percent = sum(cidx==1)/size(cidx,1);
    fprintf('--> Cluster1:%2.4f%%, Cluster2:%2.4f%%\n', cluster_1_percent*100, (1-cluster_1_percent)*100);
    silhouette(apps_metrics(:,1:6),cidx, 'cityblock');
    gcf;
    title_str = sprintf('Silhouette Measure\nK-Means (K=2, dist=cityblock)\n(Cluster1:%2.4f%%, Cluster2:%2.4f%%)', cluster_1_percent*100, (1-cluster_1_percent)*100);
    title(title_str);
    file_name = sprintf('%sclustering_cityblock_2.png', CLUSTERING_RESULT_DIR);
    saveas(f, file_name);
    close(f);
    %--------------------------------
    fprintf('Apply K-Means (K=2, dist=correlation)\n');
    f = figure;
    cidx = kmeans(apps_metrics(:,1:6),2,'distance','correlation');
    cluster_1_percent = sum(cidx==1)/size(cidx,1);
    fprintf('--> Cluster1:%2.4f%%, Cluster2:%2.4f%%\n', cluster_1_percent*100, (1-cluster_1_percent)*100);
    silhouette(apps_metrics(:,1:6),cidx, 'correlation');
    gcf;
    title_str = sprintf('Silhouette Measure\nK-Means (K=2, dist=correlation)\n(Cluster1:%2.4f%%, Cluster2:%2.4f%%)', cluster_1_percent*100, (1-cluster_1_percent)*100);
    title(title_str);
    file_name = sprintf('%sclustering_correlation_2.png', CLUSTERING_RESULT_DIR);
    saveas(f, file_name);
    close(f);
    %--------------------------------
    fprintf('Apply K-Means (K=2, dist=sqeuclidean)\n');
    f = figure;
    cidx = kmeans(apps_metrics(:,1:6),2,'distance', 'sqeuclidean');
    cluster_1_percent = sum(cidx==1)/size(cidx,1);
    fprintf('--> Cluster1:%2.4f%%, Cluster2:%2.4f%%\n', cluster_1_percent*100, (1-cluster_1_percent)*100);
    silhouette(apps_metrics(:,1:6),cidx, 'sqeuclidean');
    gcf;
    title_str = sprintf('Silhouette Measure\nK-Means (K=2, dist=sqeuclidean)\n(Cluster1:%2.4f%%, Cluster2:%2.4f%%)', cluster_1_percent*100, (1-cluster_1_percent)*100);
    title(title_str);
    file_name = sprintf('%sclustering_euclidean_2.png', CLUSTERING_RESULT_DIR);
    saveas(f, file_name);
    close(f);
    %--------------------------------
    fprintf('Apply K-Means (K=2, dist=cosine)\n');
    f = figure;
    cidx = kmeans(apps_metrics(:,1:6),2,'distance', 'cosine');
    cluster_1_percent = sum(cidx==1)/size(cidx,1);
    fprintf('--> Cluster1:%2.4f%%, Cluster2:%2.4f%%\n', cluster_1_percent*100, (1-cluster_1_percent)*100);
    silhouette(apps_metrics(:,1:6),cidx, 'cosine');
    gcf;
    title_str = sprintf('Silhouette Measure\nK-Means (K=2, dist=cosine)\n(Cluster1:%2.4f%%, Cluster2:%2.4f%%)', cluster_1_percent*100, (1-cluster_1_percent)*100);
    title(title_str);
    file_name = sprintf('%sclustering_cosine_2.png', CLUSTERING_RESULT_DIR);
    saveas(f, file_name);
    close(f);
else
    % we use method which has best clustering result
    %--------------------------------
    if REGENERATE_BEST_CLUSTERS
        cluster_best_percent = -1;
        for i=1:5        
            fprintf('Apply K-Means (K=2, dist=correlation)\n');
            cidx = kmeans(apps_metrics(:,1:6),2,'distance','correlation');
            cluster_1_percent = sum(cidx==1)/size(cidx,1);
            if cluster_1_percent > cluster_best_percent
                cluster_best_percent = cluster_1_percent;
                best_clustering_result = cidx;
                f = figure;        
                fprintf('--> Cluster1:%2.4f%%, Cluster2:%2.4f%%\n', cluster_1_percent*100, (1-cluster_1_percent)*100);
                silhouette(apps_metrics(:,1:6),cidx, 'correlation');
                gcf;
                title_str = sprintf('Silhouette Measure\nK-Means (K=2, dist=correlation)\n(Cluster1:%2.4f%%, Cluster2:%2.4f%%)', cluster_1_percent*100, (1-cluster_1_percent)*100);
                title(title_str);
                file_name = sprintf('%sclustering_correlation_2.png', CLUSTERING_RESULT_DIR);
                saveas(f, file_name);
                close(f);
            end        
        end
        save(CLUSTERS_DUMP_FILE, 'best_clustering_result');
    else
        load(CLUSTERS_DUMP_FILE);
    end       
end

%% ================= Forth Attempt ================
fprintf('Try to fit data with a Guassian Model\n');
apps_features_clusters = [apps_metrics, best_clustering_result];
normal_samples = apps_features_clusters(find(apps_features_clusters(:,8)==1),:);
suspicious_samples = apps_features_clusters(find(apps_features_clusters(:,8)==2),:);

no_apps = size(apps_metrics, 1);
no_train_set = ceil(no_apps * 0.6);
no_validation_set = floor(no_apps * 0.19);
no_test_set = floor(no_apps * 0.19);
%no_added_suspicious_samples = NO_SUSPICIOUS_SAMPLE;
no_added_suspicious_samples = floor(size(suspicious_samples,1)/2);

A=normal_samples; % a random matrix
n=no_train_set;
idx=randsample(1:size(normal_samples,1), no_train_set) ;
train_set = normal_samples(idx,:) ; % pick rows randomly
normal_samples(idx,:)=[]; % remove those rows

idx = randsample(1:size(normal_samples,1),no_validation_set) ;
validation_set_1 = normal_samples(idx,:);
normal_samples(idx,:)=[]; % remove those rows
idx = randsample(1:size(suspicious_samples,1),no_added_suspicious_samples) ;
validation_set_2 = suspicious_samples(idx,:);
suspicious_samples(idx,:)=[]; % remove those rows
validation_set = [validation_set_1; validation_set_2];

idx = randsample(1:size(normal_samples,1),no_test_set) ;
test_set_1 = normal_samples(idx,:);
normal_samples(idx,:)=[]; % remove those rows
idx = randsample(1:size(suspicious_samples,1),no_added_suspicious_samples) ;
test_set_2 = suspicious_samples(idx,:);
suspicious_samples(idx,:)=[]; % remove those rows
test_set = [test_set_1; test_set_2];

no_bins = 50;
for i=1:size(apps_features_clusters,2)-2
    if ONLY_SAVE_FIGURE
        h=figure('Visible','off');
    else
        h = figure;
    end
    %hist(train_set(:, i), no_bins); % histogram on feature values
    %hist((train_set(:, i)).^0.5, no_bins); % histogram on feature values
    %hist((train_set(:, i)).^0.2, no_bins); % histogram on feature values
    %hist((train_set(:, i)).^0.1, no_bins); % histogram on feature values
    hist(log(train_set(:, i)), no_bins); % histogram on feature values
    ylabel('Value of Feature');
    xlabel('Buckets');
    title_str = sprintf('Histogram of Feature Number %d', i);
    title(title_str);
    file_name = sprintf('%sFeature_Number_%d.png', FEATURES_FIGURES_DIR, i);
    saveas(h, file_name);
    close(h);
end
fprintf('Estimating model_1 prameters...');
train_set(:,1:6) = log(train_set(:,1:6)+0.001);
validation_set(:,1:6) = log(validation_set(:,1:6)+0.001);
test_set(:,1:6) = log(test_set(:,1:6)+0.001);
mu = mean(train_set(:,1:6));
v = var(train_set(:,1:6));
fprintf('Done\n');
fprintf('Estimating best threshold ...\n');
threshold_values = [0.0001 0.0005 0.001 0.003 0.005 0.01 0.05 0.1];
best_threshold = -1;
max_f1 = 0;
no_validation_samples = size(validation_set,1);
predictions = zeros(size(validation_set,1), 1);
for i=1:size(threshold_values,1)
    % todo: vectorize this loop    
    for j=1:no_validation_samples
        model_prob = model_1(validation_set(j, 1:6), mu, v);
        if model_prob < threshold_values(1,i)
            predictions(j,1) = 2; % predicted as suspicious sample
        else
            predictions(j,1) = 1; % predicted as normal sample
        end
    end
    model_results_evals = Evaluate(validation_set(:, 8), predictions);    
    fprintf('--> Threshlod=%f, F1=%f\n',threshold_values(1,i), model_results_evals(1,6));
    if model_results_evals(1,6)>max_f1
        best_threshold = threshold_values(1,i);
        max_f1 = model_results_evals(1,6);
    end
end

fprintf('==> Best Threshlod=%f, Best F1=%f\n',best_threshold, max_f1);

fprintf('Testing model_1 on Test Set ...\n');
min_number_of_error = 1;
max_f1 = 0;
no_test_samples = size(test_set,1);
predictions = zeros(size(test_set,1), 1);
% todo: vectorize this loop
error_counter = 0;
for j=1:no_test_samples
    model_prob = model_1(test_set(j, 1:6), mu, v);
    if model_prob < best_threshold
        predictions(j,1) = 2; % predicted as suspicious sample
    else
        predictions(j,1) = 1; % predicted as normal sample
    end    
end
model_results_evals = Evaluate(test_set(:, 8), predictions);

fprintf('--> Model_1 Results on Test Set: F1=%f\n', model_results_evals(1,6));

%% ================= Fifth Attempt ================
fprintf('Estimating model_2 prameters...');
mu = mean(train_set(:,1:6));
cov_mat = cov(train_set(:,1:6));
fprintf('Done\n');
fprintf('Estimating best threshold ...\n');
threshold_values = [0.0001 0.0005 0.001 0.003 0.005 0.01 0.05 0.1];
best_threshold = -1;
max_f1 = 0;
no_validation_samples = size(validation_set,1);
predictions = zeros(size(validation_set,1), 1);
for i=1:size(threshold_values,1)
    % todo: vectorize this loop    
    for j=1:no_validation_samples
        model_prob = model_2(validation_set(j, 1:6), mu, cov_mat)/1000;
        if model_prob < threshold_values(1,i)
            predictions(j,1) = 2; % predicted as suspicious sample
        else
            predictions(j,1) = 1; % predicted as normal sample
        end
    end
    model_results_evals = Evaluate(validation_set(:, 8), predictions);    
    fprintf('--> Threshlod=%f, F1=%f\n',threshold_values(1,i), model_results_evals(1,6));
    if model_results_evals(1,6)>max_f1
        best_threshold = threshold_values(1,i);
        max_f1 = model_results_evals(1,6);
    end
end

fprintf('==> Best Threshlod=%f, Best F1=%f\n',best_threshold, max_f1);

fprintf('Testing model_2 on Test Set ...\n');
min_number_of_error = 1;
max_f1 = 0;
no_test_samples = size(test_set,1);
predictions = zeros(size(test_set,1), 1);
% todo: vectorize this loop
error_counter = 0;
for j=1:no_test_samples
    model_prob = model_2(test_set(j, 1:6), mu, cov_mat)/1000;
    if model_prob < best_threshold
        predictions(j,1) = 2; % predicted as suspicious sample
    else
        predictions(j,1) = 1; % predicted as normal sample
    end    
end
model_results_evals = Evaluate(test_set(:, 8), predictions);

fprintf('--> Model_2 Results on Test Set: F1=%f\n', model_results_evals(1,6));

fprintf('Done\n');
