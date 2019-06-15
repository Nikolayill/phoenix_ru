#052-055
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

В `\discuss\mix.exs` были проапгрейжены зависимости:
```
	 {:ecto_sql, "~> 3.0"},
     {:phoenix_ecto, "~> 4.0"},
     {:postgrex, ">= 0.0.0"},
```

В `\discuss\lib\discuss\repo.ex` был добавлен параметр `adapter`:
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

Изменил html в шаблоне `\discuss\web\templates\page\index.html.eex`.
Изменения отобразились в браузере.

#056-057
Феникс поддерживает как приложения с рендернигом страниц на сервере, так и одностраничные.
В данном примере рассматривается рендеринг на сервере.

Папка `\discuss\web\templates\layout\` содержит макеты "layouts" для страниц,
шаблоны которых, располагаются в `\discuss\web\templates\page\`.
Файлы макетов/шаблонов имеют расширение `eex`.

Макет страниц приложения - `app.html.eex` в него имеет смысл добавлять элементы 
относящиеся к сквозной функциональности, например меню и подключение CSS стилей.

Для приложения должны использоваться стили "https://materializecss.com/".
В уроке прелоагается использовать CDN (но это не очень инстересно).
При попутке скачать стили и положить в `\discuss\web\static\vendor`, и 
затем добавить код `<link rel="stylesheet" href="<%= static_path(@conn, "/vendor/materialize/css/materialize.min.css") %>">` 
по аналогии с уже имеющимся в `app.html.eex` получаем сообщение в консоль браузера об 404 ошибке при обращении к `materialize.min.css`.
В консоль сервер выдает ошибку ` ** (Phoenix.Router.NoRouteError) no route found for GET /vendor/material....`.

Решение "в меру непонимания проблемы" в файле `\discuss\lib\discuss\endpoint.ex`: добавил `vendor` в код:
```
plug Plug.Static,
	at: "/", from: :discuss, gzip: false,
	only: ~w(css fonts images js vendor favicon.ico robots.txt)
```
CSS из папки vendor начали раздаваться...

#058-059
##Router-Controller
Модуль "роутер" определяет какой компонент приложения будет обрабатывать конкретный входящий запрос.
Код роутера расположен в `\discuss\web\router.ex`

Секция начинающаяся словом `scope` определяет скоуп для которого указываются правила обработки запросов.
Например `scope "/"` действует для запросов начинающихся с `/`.

Код `get "/", PageController, :index` указывает что при GET запросе к URL `/` 
нужно обратиться к функции `index` модуля `PageController` (`\discuss\web\controllers\page_controller.ex`). 
Эта функция и станет обработчиком запроса.

Для данного скоупа указан определенный пайплайн `pipe_through :browser`
-- помеченный символом `:browser`.
Сам пайплайн определен выше: `pipeline :browser`.

#060
##Views
Феникс неявно связывает модули представления (views) с файлами шаблонов (templates) в определенной папке.
Для связывания используются соглашения об именовании. Так шаблоны в папке `web/templates/page`
будут связаны с `web/views/page_view.ex`.
В модуль представления добавляется функция `render` которая "видит" шаблоны из связанной папки.
Например, если запусть феникс+iex:\
`iex -S mix phoenix.server` и выполнить `Discuss.PageView.render("index.html")`, в консоли отобразится
код отрендереной страницы.

#061-062
##Models
Модель представляет собой отображение записи из таблицы БД. 
Создание модели в БД начинается с генерации файла миграций (migration file) командой:\
`mix ecto.gen.migration add_topics`, где `add_topics` формальное название операции которая будет выполнена 
(добавление таблицы для хранения тем форума).
В консоль будет выдано сообщение вида `* creating priv/repo/migrations/20190612224957_add_topics.exs`
о том, что был сгененрирован скрипт `20190612224957_add_topics` по указанному пути.

В скрипте будет расположена пустая функция `change`, что бы создать таблицу в нее нужно добавить код:
```
  def change do
    create table(:topics) do
      add :title, :string
    end
  end
```
который указывает, что нужно создать таблицу `topics`
у которой должна быть текстовая колонка `title`.
Далее, что бы выполнить изменения в БД, нужно запустить миграцию командой:
`mix ecto.migrate`. Она выдаст в консоль отчет о выполнении
```
01:59:50.375 [info]  == Running 20190612224957 Discuss.Repo.Migrations.AddTopics.change/0 forward

01:59:50.375 [info]  create table topics

01:59:50.381 [info]  == Migrated 20190612224957 in 0.0s
```
И в базе данных появится таблица `topics` и последовательность `topics_id_seq`. 
Так же в БД появится таблица `schema_migrations` с метаинформацией о выполненных миграциях.

#063-064
Создание топика на форуме начинается с того что пользователь заходит на страницу формы: `/topics/new`.
Т.е. на сервер будет отправлен GET запрос по указанному URL. Что бы запрос был обработан
нужно добавить его в роутер `get "/topics/new", TopicController, :new`, 
так же нужно создать контроллер `TopicController`.

#065
##TopicController
По соглашению название модуля контроллера соответствует сущности в ед.числе, 
которую он обслуживает. Т.е. `topics` - `TopicController`.
В контроллере должна быть функция-обработчик `new` указанная в роутере (на пред. шаге).
Т.о. модуль будет выглядеть так:
```
defmodule Discuss.TopicController do
  def new() do

  end
end
```
Теперь, если запустить феникс, он не выдаст ошибки при старте.
Но при попытке открыть указанную страницу произойдет исключение:
```
Request: GET /topics/new
** (exit) an exception was raised:
    ** (UndefinedFunctionError) function Discuss.TopicController.init/1 is undefined or private    
```

#066
##import-alias-use
Феникс ожидает от контроллера некоторого определенного поведения. 
В элексире нет наследования как в ОО-языках, но есть ряд собственных решений
для переиспользования кода.
`import` - дает доступ из модуля к функциям другово модуля.\
`alias` - создает шорткат к другому модулю.\
`use` - позволяет "гибко" (?) связать модули.\

Например:
существует модуль `Math`
```
defmodule Math do
  def add(a,b), do: a+b
end
```
что бы в модуле `TopicController` использовать функцию `add`,
можно обратиться к ней через полное имя модуля:
```
defmodule TopicController do
  def new() do
	Math.add(1,2)
  end
end
```
 
если в модуле `TopicController` написать `import Math`, 
функция `add` станет доступна извне как `TopicController.add`:
```
defmodule TopicController do
  import Math
  
  def new() do
	add(1,2)
  end
end
```

если в модуле `TopicController` написать `alias Math`, 
функция `add` будет доступна только в самом `TopicController`:
```
defmodule TopicController do
  alias Math
  
  def new() do
	add(1,2)
  end
end
```

#067
##use
Для "наследования" общего поведения контроллера используется выражение 
`use Discuss.Web, :controller` (см. `web/controllers/page_controller.ex` стр.2).
`use` позволяет гибко настраивать импорты. 
В данном примере в выражении содержится ссылка на функцию `controller` 
в модуле `Discuss.Web`.

Модуль `Discuss.Web` (см.`web/web.ex`) содержит такой код:
```
  def controller do
    quote do
      use Phoenix.Controller

      alias Discuss.Repo
      import Ecto
      import Ecto.Query

      import Discuss.Router.Helpers
      import Discuss.Gettext
    end
  end
``` 
В нём указана целая группа импортов, которые и будут подключены к модулю контроллера
`use Discuss.Web, :controller`.
В модуле `Discuss.Web` есть такие функции для всех основных частей приложения
(model, view, router, controller, channel).
Если в проекте появится некоторая общая функциональность, то ее можно вынести
в отдельный модуль и добавить импорт в соответствующую функцию.
 
Например, новая функциональность помещена в модуль `Discuss.CustomHelpers`, тогда
что бы подключить её к каждому контроллеру нужно модифицировать код так:
```
  def controller do
    quote do
      use Phoenix.Controller

      alias Discuss.Repo
      import Ecto
      import Ecto.Query

      import Discuss.Router.Helpers
      import Discuss.Gettext
      import Discuss.CustomHelpers # <-- функции нужные в каждом контроллере 
    end
  end
```

PS: здесь используется метапрограммирование - блок `quote` (см. https://elixirschool.com/ru/lessons/advanced/metaprogramming/#quote).
По сути `use` встраивает блок содержащийся в `quote` в код модуля.





