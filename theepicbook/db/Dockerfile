FROM mysql:8.0
COPY BuyTheBook_Schema.sql /docker-entrypoint-initdb.d/01-schema.sql
COPY author_seed.sql /docker-entrypoint-initdb.d/02-authors.sql
COPY books_seed.sql /docker-entrypoint-initdb.d/03-books.sql
