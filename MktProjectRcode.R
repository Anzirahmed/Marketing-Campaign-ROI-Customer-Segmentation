library(dplyr)
library(ggplot2)
library(factoextra)
library(cluster)

#  Load the dataset
df <- read.csv("marketing_cluster_features.csv")

#  Inspect structure and column names
names(df)
str(df)
head(df)

# Standardize column names to lowercase (avoid case-sensitivity issues)
names(df) <- tolower(names(df))

# Select features for clustering
features <- df %>%
  select(income, total_spend, web_purchases, catalog_purchases, store_purchases, recency_days)

# Scale numeric data (normalize units)
scaled_data <- scale(features)

#  Determine optimal number of clusters
set.seed(42)

# Elbow method
fviz_nbclust(scaled_data, kmeans, method = "wss") +
  labs(title = "Elbow Method for Optimal K")

# Silhouette method
fviz_nbclust(scaled_data, kmeans, method = "silhouette") +
  labs(title = "Silhouette Method for Optimal K")

# Apply K-Means clustering (usually k = 4 works well for this dataset)
set.seed(123)
k <- 4
km_model <- kmeans(scaled_data, centers = k, nstart = 25)

# Add cluster assignments to the main dataframe
df$cluster <- km_model$cluster

# Visualize clusters in 2D using PCA projection
fviz_cluster(km_model, data = scaled_data, geom = "point",
             ellipse.type = "norm", palette = "jco",
             main = "Customer Segments (K-Means Clusters)")

# Summarize cluster characteristics
cluster_summary <- df %>%
  group_by(cluster) %>%
  summarise(
    avg_income = mean(income, na.rm = TRUE),
    avg_spend = mean(total_spend, na.rm = TRUE),
    avg_recency = mean(recency_days, na.rm = TRUE),
    avg_web = mean(web_purchases, na.rm = TRUE),
    avg_catalog = mean(catalog_purchases, na.rm = TRUE),
    avg_store = mean(store_purchases, na.rm = TRUE),
    avg_response = mean(response, na.rm = TRUE),
    n_customers = n()
  ) %>%
  arrange(desc(avg_spend))

print(cluster_summary)

# Assign segment labels (optional, based on interpretation)
segment_labels <- c("Premium Loyalists", "Potential Upgraders",
                    "Price Sensitive", "Inactive Low-Value")
df$segment <- segment_labels[df$cluster]

# Preview labeled customers
head(df[, c("customer_id", "segment", "income", "total_spend", "response")])

# Save final segmented dataset
write.csv(df, "marketing_customers_segmented.csv", row.names = FALSE)

