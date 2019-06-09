Что бы создать новый проект, выполнил:
`mix phoenix.new discuss`
При попытке выполнить:
`mix ecto.create`\
на сгененрированном проекте, получал сообщение:
```
== Compilation error in file lib/discuss/repo.ex ==
** (ArgumentError) missing :adapter option on use Ecto.Repo
    lib/ecto/repo/supervisor.ex:66: Ecto.Repo.Supervisor.compile_config/2
    lib/discuss/repo.ex:2: (module)
    (stdlib) erl_eval.erl:680: :erl_eval.do_apply/6
    (elixir) lib/kernel/parallel_compiler.ex:198: anonymous fn/4 in Kernel.Paral
lelCompiler.spawn_workers/6
```

Помог ответ 
https://stackoverflow.com/a/53057831
в топике
https://stackoverflow.com/questions/53045717/adapter-ecto-adapters-postgres-was-not-compiled

В `mix.exs` были проапгрейжены зависимости:
```
	 {:ecto_sql, "~> 3.0"},
     {:phoenix_ecto, "~> 4.0"},
     {:postgrex, ">= 0.0.0"},
```

В `repo.ex` был добавлен параметр `adapter`:
```
defmodule Discuss.Repo do
  use Ecto.Repo, 
	otp_app: :discuss,
	adapter: Ecto.Adapters.Postgres
end
```

Затем выполнил:
```
mix deps.clean --all
mix do deps.get, compile
```
получил варнинги, но ошибок не было.
Выполнил `mix ecto.create` и получил вывод:
`The database for Discuss.Repo has already been created`
что вероятно говорит об успехе.

Запустил сервер командой `mix phoenix.server`. 
По адресу `http://localhost:4000` стала доступна чистая страничка.
