from datetime import datetime, timedelta

from airflow import DAG
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.operators.python import PythonOperator

default_args = {
    "owner": "solo",
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
}


def extract(**context):
    hook = PostgresHook(postgres_conn_id="ecommerce_db")
    orders = hook.get_records(
        """
        SELECT o.id, o.customer_name, o.customer_email, o.total_amount, o.created_at,
               oi.product_id, oi.quantity, oi.unit_price
        FROM orders o
        JOIN order_items oi ON oi.order_id = o.id
        WHERE o.created_at >= now() - interval '1 day';
        """
    )
    context["ti"].xcom_push(key="raw_orders", value=orders)


def transform(**context):
    raw_orders = context["ti"].xcom_pull(key="raw_orders", task_ids="extract")
    transformed = []
    for row in raw_orders:
        (order_id, name, email, total, created_at, product_id, qty, unit_price) = row
        transformed.append(
            {
                "order_id": order_id,
                "customer_email": email,
                "product_id": product_id,
                "quantity": qty,
                "revenue": float(qty) * float(unit_price),
                "order_date": created_at.date().isoformat(),
            }
        )
    context["ti"].xcom_push(key="clean_orders", value=transformed)


def load(**context):
    clean_orders = context["ti"].xcom_pull(key="clean_orders", task_ids="transform")
    hook = PostgresHook(postgres_conn_id="warehouse_db")
    for row in clean_orders:
        hook.run(
            """
            INSERT INTO fact_orders (order_id, customer_email, product_id, quantity, revenue, order_date)
            VALUES (%(order_id)s, %(customer_email)s, %(product_id)s, %(quantity)s, %(revenue)s, %(order_date)s)
            ON CONFLICT (order_id, product_id) DO NOTHING;
            """,
            parameters=row,
        )


with DAG(
    dag_id="etl_ecommerce_orders",
    default_args=default_args,
    description="ETL quotidien des commandes du site e-commerce vers le data warehouse",
    schedule_interval="@daily",
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["ecommerce", "etl"],
) as dag:

    t_extract = PythonOperator(task_id="extract", python_callable=extract)
    t_transform = PythonOperator(task_id="transform", python_callable=transform)
    t_load = PythonOperator(task_id="load", python_callable=load)

    t_extract >> t_transform >> t_load
