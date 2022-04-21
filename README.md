# anomaly-detection-for-marketplaces
A project for addressing anomaly detection practices in Matlab for marketplace platforms.

# Problem Definition
The goal is to find goods whose purchase shows suspicious behavior. From a data analysis perspective, Suspicious behavior is any behavior that conflicts with the behavior of others and the majority of goods. From an operational and intuitive point of view, suspicious behavior is a behavior that some people use to raise the ranking of goods in different stores. This product can be a physical product or an application in markets such as Google Play or App Store. For example, creating abnormal downloads, making irregular purchase orders in bursts or with continuous patterns, etc., can be signs of anomalies.
Various information is usually available to find suspicious behavior in the web and mobile domains. For example, IP address, type of platform used, time, etc., can be factors recorded in the log and used as valuable features. Here, only the product or app ID and purchase times are available, and the issue should be analyzed and resolved accordingly.

# Dataset
The data set provided is a CSV file that contains two columns. The first column contains the ID for each product or application, and in the second column is the time of the "purchase." The time here is recorded as Timestamp and the time quantum in the system in seconds. The file contains 301401 entries, each inserted in a row.


# The First Attempt
To better understand the data, we first calculate statistics from the status of the data we have. The first point is that here in the data set, the data is sorted by the ID of each app, not by time. The time format used here is the Timestamp format used in Unix, and the timezone is set to Iran's, from 9/6/1974, 12:00:00 AM to 4/6/1975, 10:59:00 PM. It is approximately 212 days.
<br />
Therefore, the period discussed for applications is approximately 212 (approximately 213) days. Now let's look at the number of apps in the data set and their status. There are a total of 99,340 apps in the dataset. The statistics related to the number of purchases are as follows:
1. Minimum number of purchases: 1
2. Maximum number of purchases: 721
3. The average number of purchases is: 3.0340
4. The variance of the purchase number is: 77.9909


Based on these statistics and their frequency, there are some interesting points. For example, we have 55,143 apps that have only been ordered once! Approximately 83.9% of apps have lower than average purchases. In other words, given that the average number of orders here is 3,034, an enormous volume of apps have only been ordered 1 to 3 times. Apps that are so unpopular do not seem to be of much help in reaching a model for detecting suspicious apps. Apps with this small number of orders are probably just commissioned by the developer.
Here, to get a more accurate model, we exclude the apps with one purchase from the data set so that the behavior of the other apps can be better considered. To better understand the subject, we include the top apps that have more purchases in our considerations. For example, in Figure 1., the top 20 apps are considered, and their purchase histogram chart is drawn based on the time.

<div align="center">
  Figure.1 20-app histogram has the most orders in time (seconds). 
</div>

| ![id=6499, purchases=721, rank=1](figures/hists/6499_721_1.png)   | ![id=424300, purchases=488, rank=2](figures/hists/424300_488_2.png)     | ![id=16806, purchases=465, rank=3](figures/hists/16806_465_3.png)    |
| :---         |     :---:      |          ---: |
| ![id=55510, purchases=428, rank=4](figures/hists/55510_428_4.png)   | ![id=95933, purchases=424, rank=5](figures/hists/95933_424_5.png)     | ![id=64264, purchases=359, rank=6](figures/hists/64264_359_6.png)    |
| ![id=67689, purchases=339, rank=7](figures/hists/67689_339_7.png)   | ![id=423877, purchases=323, rank=8](figures/hists/423877_323_8.png)     | ![id=54804, purchases=321, rank=9](figures/hists/54804_321_9.png)    |
| ![id=14227, purchases=314, rank=10](figures/hists/14227_314_10.png)   | ![id=961938, purchases=311, rank=11](figures/hists/961938_311_11.png)     | ![id=963526, purchases=294, rank=12](figures/hists/963526_294_12.png)    |
| ![id=12281, purchases=281, rank=13](figures/hists/12281_281_13.png)   | ![id=27292, purchases=275, rank=14](figures/hists/27292_275_14.png)     | ![id=51554, purchases=245, rank=15](figures/hists/51554_245_15.png)    |
| ![id=1227, purchases=233, rank=16](figures/hists/1227_233_16.png)   | ![id=18966, purchases=233, rank=17](figures/hists/18966_233_17.png)     | ![id=63719, purchases=226, rank=18](figures/hists/63719_226_18.png)    |
| ![id=49365, purchases=220, rank=19](figures/hists/49365_220_19.png)   | ![id=1196204, purchases=217, rank=20](figures/hists/1196204_217_20.png)     |     |


 

# Repository Structure
