from datetime import datetime, timedelta

# Добавляем timestamp к данным
import pandas as pd
from feast import Entity, FeatureView, Field, FileSource, ValueType
from feast.types import Float32, Int32


# Функция для добавления timestamp
def add_timestamps():
    now = datetime.now()
    for file in ["carrier_stats.csv", "airport_stats.csv", "hourly_stats.csv"]:
        df = pd.read_csv(f"data/{file}")
        df["event_timestamp"] = now
        df["created_timestamp"] = now
        df.to_csv(f"data/{file}", index=False)
    print("✅ Timestamps добавлены")


# Источники данных
carrier_source = FileSource(
    path="data/carrier_stats.csv",
    timestamp_field="event_timestamp",
    created_timestamp_column="created_timestamp",
)

airport_source = FileSource(
    path="data/airport_stats.csv",
    timestamp_field="event_timestamp",
    created_timestamp_column="created_timestamp",
)

hourly_source = FileSource(
    path="data/hourly_stats.csv",
    timestamp_field="event_timestamp",
    created_timestamp_column="created_timestamp",
)

# Сущности с value_type
carrier = Entity(
    name="carrier",
    value_type=ValueType.STRING,
    join_keys=["carrier"],
    description="Авиакомпания",
)

airport = Entity(
    name="airport",
    value_type=ValueType.STRING,
    join_keys=["airport"],
    description="Аэропорт",
)

hour = Entity(
    name="hour",
    value_type=ValueType.INT32,
    join_keys=["hour"],
    description="Час дня",
)

# Feature Views
carrier_stats_view = FeatureView(
    name="carrier_statistics",
    entities=[carrier],
    ttl=timedelta(days=365),
    schema=[
        Field(name="avg_dep_delay", dtype=Float32),
        Field(name="std_dep_delay", dtype=Float32),
        Field(name="flight_count", dtype=Int32),
        Field(name="avg_arr_delay", dtype=Float32),
        Field(name="std_arr_delay", dtype=Float32),
        Field(name="delay_rate", dtype=Float32),
    ],
    source=carrier_source,
)

airport_stats_view = FeatureView(
    name="airport_statistics",
    entities=[airport],
    ttl=timedelta(days=365),
    schema=[
        Field(name="avg_dep_delay", dtype=Float32),
        Field(name="dep_delay_rate", dtype=Float32),
        Field(name="flight_count_origin", dtype=Int32),
        Field(name="avg_arr_delay", dtype=Float32),
        Field(name="arr_delay_rate", dtype=Float32),
        Field(name="flight_count_dest", dtype=Int32),
    ],
    source=airport_source,
)

hourly_stats_view = FeatureView(
    name="hourly_statistics",
    entities=[hour],
    ttl=timedelta(days=365),
    schema=[
        Field(name="avg_delay", dtype=Float32),
        Field(name="delay_rate", dtype=Float32),
        Field(name="flight_count", dtype=Int32),
    ],
    source=hourly_source,
)

# Добавляем timestamps при импорте
add_timestamps()
