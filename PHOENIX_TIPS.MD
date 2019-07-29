# Предварительные шаги
См. в [README.md](README.md)

# 052-055
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
```Elixir
	 {:ecto_sql, "~> 3.0"},
     {:phoenix_ecto, "~> 4.0"},
     {:postgrex, ">= 0.0.0"},
```

В `\discuss\lib\discuss\repo.ex` был добавлен параметр `adapter`:
```Elixir
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

# 056-057
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
```Elixir
plug Plug.Static,
	at: "/", from: :discuss, gzip: false,
	only: ~w(css fonts images js vendor favicon.ico robots.txt)
```
CSS из папки vendor начали раздаваться...

# 058-059
## Router-Controller
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

# 060
## Views
Феникс неявно связывает модули представления (views) с файлами шаблонов (templates) в определенной папке.
Для связывания используются соглашения об именовании. Так шаблоны в папке `web/templates/page`
будут связаны с `web/views/page_view.ex`.
В модуль представления добавляется функция `render` которая "видит" шаблоны из связанной папки.
Например, если запусть феникс+iex:\
`iex -S mix phoenix.server` и выполнить `Discuss.PageView.render("index.html")`, в консоли отобразится
код отрендереной страницы.

# 061-062
## Models
Модель представляет собой отображение записи из таблицы БД. 
Создание модели в БД начинается с генерации файла миграций (migration file) командой:\
`mix ecto.gen.migration add_topics`, где `add_topics` формальное название операции которая будет выполнена 
(добавление таблицы для хранения тем форума).
В консоль будет выдано сообщение вида `* creating priv/repo/migrations/20190612224957_add_topics.exs`
о том, что был сгененрирован скрипт `20190612224957_add_topics` по указанному пути.

В скрипте будет расположена пустая функция `change`, что бы создать таблицу в нее нужно добавить код:
```Elixir
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

# 063-064
Создание топика на форуме начинается с того что пользователь заходит на страницу формы: `/topics/new`.
Т.е. на сервер будет отправлен GET запрос по указанному URL. Что бы запрос был обработан
нужно добавить его в роутер `get "/topics/new", TopicController, :new`, 
так же нужно создать контроллер `TopicController`.

# 065
## TopicController
По соглашению название модуля контроллера соответствует сущности в ед.числе, 
которую он обслуживает. Т.е. `topics` - `TopicController`.
В контроллере должна быть функция-обработчик `new` указанная в роутере (на пред. шаге).
Т.о. модуль будет выглядеть так:
```Elixir
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

# 066
## import-alias-use
Феникс ожидает от контроллера некоторого определенного поведения. 
В элексире нет наследования как в ОО-языках, но есть ряд собственных решений
для переиспользования кода.
`import` - дает доступ из модуля к функциям другово модуля.\
`alias` - создает шорткат к другому модулю.\
`use` - позволяет "гибко" (?) связать модули.\

Например:
существует модуль `Math`
```Elixir
defmodule Math do
  def add(a,b), do: a+b
end
```
что бы в модуле `TopicController` использовать функцию `add`,
можно обратиться к ней через полное имя модуля:
```Elixir
defmodule TopicController do
  def new() do
	Math.add(1,2)
  end
end
```
 
если в модуле `TopicController` написать `import Math`, 
функция `add` станет доступна извне как `TopicController.add`:
```Elixir
defmodule TopicController do
  import Math
  
  def new() do
	add(1,2)
  end
end
```

если в модуле `TopicController` написать `alias Math`, 
функция `add` будет доступна только в самом `TopicController`:
```Elixir
defmodule TopicController do
  alias Math
  
  def new() do
	add(1,2)
  end
end
```

# 067
## use
Для "наследования" общего поведения контроллера используется выражение 
`use Discuss.Web, :controller` (см. `web/controllers/page_controller.ex` стр.2).
`use` позволяет гибко настраивать импорты. 
В данном примере в выражении содержится ссылка на функцию `controller` 
в модуле `Discuss.Web`.

Модуль `Discuss.Web` (см.`web/web.ex`) содержит такой код:
```Elixir
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
```Elixir
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

# 068
##  Параметры функции контроллера
Теперь при попытке запустить сервер возникает другая ошибка:
```
Request: GET /topics/new
** (exit) an exception was raised:
    ** (UndefinedFunctionError) function Discuss.TopicController.new/2 is undefined or private. Did you mean one of:

      * new/0
```
Строка `function Discuss.TopicController.new/2 is undefined or private.` указывает что в контроллере недоступна функция
`new` с ожидаемым количеством параметров (2).
В эликсире количество параметров указывается следом за именем функции, между именем и числом ставится слэш.

Можно добавить параметры по аналогии с `web/controllers/page_controller.ex` и попытаться вывести их значения на экран.
#### IO.puts, IO.inspect
 Функция `IO.puts` выводит строку на экран\
 Функция `IO.inspect` выводит значение структуры данных и её вложенных частей.\
 С помощью этих функций можно увидеть, что за значения передаются в контроллер. 
 
Текст ошибки при обращении к странице, снова поменяется:
```
Request: GET /topics/new
** (exit) an exception was raised:
    ** (RuntimeError) expected action/2 to return a Plug.Conn, all plugs must receive a connection (conn) and return a connection
```
И в консоли появятся значения параметров:\
`conn` содержит структуру `%Plug.Conn{ *** }` заполненную параметрами и заголовками HTTP запроса 
и некоторыми дополнительными значениями.\
`params` в данном случае будет пустой ассоциативный массив `%{}`, но если посторить запрос добавив параметр:
`http://localhost:4000/topics/new?test=1` то в массиве будет `%{"test" => "1"}`.

## Plug.Conn
`Plug.Conn` содержит входящий HTTP запрос, и в такой же структуре должен содержаться ответ. 
Эта структура используется на всех этапах обработки запроса в фениксе.  

# 069-070
## model
Что бы реализовать форму для создания новой темы форума, нужна модель которая будет представлять данные в форме.
Модель `Discuss.Topic` будет размещена в `web/models/discuss/topic.ex`. 
Как упоминалось выше (см. "067") в модуль нужно добавить некоторые общие функции: `use Discuss.Web, :model`.

Модель должна содержать схему данных, которую будет использовать феникс.
```Elixir
  schema "topics" do
    field :title, :string
  end
```
Схема указывает фениксу, что данные для модели хранятся в таблице `topics` которая имеет текстовое поле `title`.

# 071-073
## Валидация модели
#### Changeset
В модуле `Discuss.Topic` можно определить функцию валидации.\
Для валидации данных модели используется модуль и структура `Ecto.Changeset` (см.https://elixirschool.com/en/lessons/ecto/changesets/)
Пустая структура имеет вид:
```
iex(6)> %Ecto.Changeset{}
 #Ecto.Changeset<action: nil, changes: %{}, errors: [], data: nil, valid?: false>
```
Что бы ее заполнить нужно воспользоваться функцией `Ecto.Changeset.cast/4`:
```
iex(8)> Ecto.Changeset.cast(%Discuss.Topic{title: "Test"}, %{"title" => "New title"}, [:title])
#Ecto.Changeset<
  action: nil,
  changes: %{title: "New title"},
  errors: [],
  data: #Discuss.Topic<>,
  valid?: true
>
```
Функция первым параметром принимает исходное значение валидируемой структуры, вторым параметром - измененное значение,
третьим параметром - набор отслеживаемых полей. Изменение других полей не будет обработано, - если в примере выше, 
изменить третий параметр на пустой список, то функция верент пустую структуру:
```
iex(9)> Ecto.Changeset.cast(%Discuss.Topic{title: "Test"}, %{"title" => "New title"}, [])
#Ecto.Changeset<action: nil, changes: %{}, errors: [], data: #Discuss.Topic<>,
 valid?: true>
```
#### Функции-валидаторы (Ecto.Changeset.validate_required)
В `Ecto` существует набор предопределенных функций варидации. Для валидации `Discuss.Topic` 
в модуль нужно добавить функцию формирующую changeset и применяющую к нему валидатор:
```Elixir
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title])
    |> validate_required([:title])
  end
```
здесь `validate_required` - один из валидаторов `Ecto` указывающий, что поле `title` обязательно должно быть заполнено.
Пример:
```
iex(14)> Ecto.Changeset.cast(%Discuss.Topic{title: ""}, %{"title" => "New topic"}, [:title]) |> Ecto.Changeset.validate_required([:title])
#Ecto.Changeset<
  action: nil,
  changes: %{title: "New topic"},
  errors: [],
  data: #Discuss.Topic<>,
  valid?: true
>
```
флаг `valid?: true` указывает, что после изменения запись валидна.
Если поменять второй параметр на `%{"title" => ""}` (поле `title` содержит пустую строку):
```
iex(15)> Ecto.Changeset.cast(%Discuss.Topic{title: ""}, %{"title" => ""}, [:title]) |> Ecto.Changeset.validate_required([:title])
#Ecto.Changeset<
  action: nil,
  changes: %{},
  errors: [title: {"can't be blank", [validation: :required]}],
  data: #Discuss.Topic<>,
  valid?: false
>
```
Валидатор выставит флаг `valid?: false` - запись не валидна, а в поле `errors`
будет указано сообщение и причина.

##### Значение аргумента функции по умолчанию
В приведенном выше примере функции `changeset` за вторым аргументом 
`params` следует двойной слэш `\\` и значение `%{}` - пустой асоц.массив:\
`def changeset(struct, params \\ %{}) do`\
Так в элексире обозначается значение аргумента по умолчанию. 

# 074
## view + template 
Что бы создать представление для формы, нужно добавить модуль `TopicView` в каталог `views`.
В соответствии с соглашением файл будет называться: `web/views/topic_view.ex`.\
В этот модуль нужно добавить импорт функциональности представления: `use Discuss.Web, :view`.\
Так же нужно создать шаблон HTML формы.\
По соглашению, он должен располагаться в каталоге `web/templates/topic`.\
Сейчас в шаблоне можно указать тестовый код `<h1>New Test Form</h1>`, 
что бы предварительно проверить будет ли он рендериться.
В контроллере `TopicController`, функцию `new` нужно дополнить командой рендеринга шаблона:
```Elixir
  def new(conn, params) do
    changeset = Topic.changeset(%Topic{}, %{})
    
    render conn, "new.html"
  end
```
Теперь можно попробовать запустить сервер `mix phoenix.server`
и открыть `http://localhost:4000/topics/new` - 
на экране должен появиться текст который был внесен в шаблон.

# 075
## template
Форму можно создать на основе ченьжсета используемой модели.\
Для этого нужно использовать встраиваемый в шаблон код. Например, если в шаблон добавить строчку:
```
<%= 1 + 1 %>
```
то код заключенный между `<%=` и `%>`, 
будет вычислен и результат вычисления отображен на странице.

Генерация кода формы происходит в функции `form_for`, 
генерация поля ввода в `text_input` и кнопки в `submit`.\
При рендере шаблона в него могут быть переданы некоторые значения (контекст), 
 к ним можно обратиться по имени начинающемся с символа `@`.\
Контекст - это ассоциативный массив который передается третьим 
параметром функции `render` в контроллере:
```Elixir
render conn, "new.html", changeset: changeset
```
Шаблон обращается к значениям по их ключам `@changeset`.\
Структура `conn` всегда передается в шаблон и доступна через `@conn`.
Теперь если открыть страницу формы, появится сообщение об ошибке:
```
Request: GET /topics/new
** (exit) an exception was raised:
    ** (ArgumentError) No helper clause for Discuss.Router.Helpers.topic_path/2 defined for action :create.
The following topic_path actions are defined under your router:

  * :new
```

# 076
## REST-соглашения, обработчик POST запроса
Ошибка происходит т.к. феникс не находит ожидаемый обработчик запросов.
Феникс следует REST-соглашениям для доступа к ресурсам:

**цель** |**запрос**  | **функция контроллера**
-----:|:-------|:---------------------
получить страницу с формой | **GET** '/topic/new' | new
отправить форму | **POST** '/topics' | create
получить список всех тем | **GET** '/topics' | index
удалить тему с ID = 12 | **DELETE** '/topics/12' | delete
получить страницу с формой редактирования записи с ID = 12 | **GET** '/topics/12/edit' | edit
отправить форму с изменениями в записи с ID = 12 | **PUT** '/topics/12' | update

Т.о. в роутере нужно определить новый путь: `post "/topics", TopicController, :create`.
Теперь при открытии страницы отображается форма с полем ввода и кнопкой.
Но при нажатии кнопки мы будем получать ошибку, т.к. сам обработчик в контроллере не определен.

Если определить в контроллере функцию `create`:
```Elixir
  def create(conn, params) do
    IO.inspect(params)
  end
```
И попытаться отправить заполненную форму, в консоль будет выведено значение в `params`:
```Elixir
%{
  "_csrf_token" => "CDELFDhzXCEGWwF5OgJoFAgTCScFAAAAFFbyz43dV8gKRlQLqYMwgw==",
  "_utf8" => "тЬУ",
  "topic" => %{"title" => "gfdgd"}
}
```
Видно, что данные введенные в поле попадают в параметр "topic", значением в котором является ассоциативный массив,
в котором каждому полю формы соответствует отдельный ключ.
#### Ассоциативный массив
[Ассоциативный массив](https://elixirschool.com/ru/lessons/basics/collections/#%D0%B0%D1%81%D1%81%D0%BE%D1%86%D0%B8%D0%B0%D1%82%D0%B8%D0%B2%D0%BD%D1%8B%D0%B5-%D0%BC%D0%B0%D1%81%D1%81%D0%B8%D0%B2%D1%8B) это неупорядоченная коллекция пар ключ-значение, 
где ключем может являться любое значение, а не только атом как в ключевых списках.\
Что бы получить из него данные можно воспользоваться паттер матчингом:
`%{"topic" => topic} = params`\
тогда в переменную `topic` попадет значение по ключу `"topic"`, т.е. `%{"title" => "gfdgd"}`.\
Выражения паттерн матчинга может использоваться непосредственно вместо аргументов функции:
```Elixir
  def create(conn, %{"topic" => topic} = params) do
```
здесь `%{"topic" => topic} = params` означает - сопоставить второй аргумент с образцом и поместить
значение с ключем `"topic"` в переменную `"topic"`, 
а полное значение второго аргумента поместить в `params`. 
# 077
#### Router.Helpers
Команда (задача) `mix phoenix.routes` отображает в консоль пути определаенные в проекте.\
Например, если её выполнить для данного проекта, она должна вывести:
```
 page_path  GET   /            Discuss.PageController :index
topic_path  GET   /topics/new  Discuss.TopicController :new
topic_path  POST  /topics      Discuss.TopicController :create
```
в первой колонке имя [функции хелпера](https://hexdocs.pm/phoenix/routing.html#path-helpers)
генерируемой для конкретного контроллера, ассоциированного с ним URL и типа HTTP запроса.
Хелперы служат для абстрагирования от конкретных путей при указании URL. Например в шаблоне:
`web/templates/topic/new.html.eex` для указания пути отправки из формы: `<%= form_for @changeset, topic_path(@conn, :create), fn f -> %>`.
Здесь `topic_path(@conn, :create)` вернет `/topics`:
```
iex(1)> alias Discuss.Router.Helpers, as: Routes
Discuss.Router.Helpers
iex(2)> Routes.topic_path(%Plug.Conn{}, :new)
"/topics/new"
```
# 078
## Repo
Для вставки записи в таблицу БД используется функция `Repo.insert/1` принимающая в к-ве аргумента
структуру("changeset") сгененрированную с помощью `Topic.changeset`. Т.о. минимально, 
функция контроллера `Discuss.TopicController.create` должна содержать:
```Elixir
	changeset = Topic.changeset(%Topic{}, topic)
	Repo.insert(changeset)
```
Так же следует добавить проверку результата. `Repo.insert` - функция возвращает кортеж первый элемент
которого атом `ok:` в случае успешного выполнения и `error:` в случае ошибки.
```Elixir
    case Repo.insert(changeset) do
      {:ok, post} -> IO.inspect(post)
      {:error, changeset} -> IO.inspect(changeset) #обработка ошибки
    end
```
Если теперь запустить сервере `mix phoenix.server`, открыть форму `http://localhost:4000/topics/new`,
заполнить название и нажать кнопку "Save Topic" - в таблицу будет выполнена вставка. После нажатия кнопки
будет отображена страница ошибки т.к. код из примера выше не возвращает HTTP ответ - структуру `Plug.Conn`.

В логе будут отображены данные формы:
```
[debug] Processing by Discuss.TopicController.create/2
  Parameters: %{"_csrf_token" => "JTwjUDcVPhI0WmpaFj42ERIxBgEHAAAAdDbaOpQfL/9nyNPdfpjvbA==", "_utf8" => "тЬУ", "topic" => %{"title" => "gfdgd"}}
```
затем сформированный SQL запрос и значение структуры:
```Elixir
%Discuss.Topic{
  __meta__: #Ecto.Schema.Metadata<:loaded, "topics">,
  id: 1,
  title: "JS frameworks"
}
```
#### [error] an exception was raised logging %DBConnection.LogEntry
Сейчас при выполнении появляется ошибка `[error] an exception was raised logging %DBConnection.LogEntry`.
Предположительно это связано с тем, что в приложении не запускается необходимый процесс `ecto_sql`.
Что бы исправить, нужно прописать `ecto_sql` в `mix.exs`:
```Elixir
  def application do
    [mod: {Discuss, []},
     applications: [:phoenix, :phoenix_pubsub, :phoenix_html, :cowboy, :logger, :gettext, 
     :ecto_sql,
     :phoenix_ecto, :postgrex]]
  end
```
нужно добавить `:ecto_sql` в список по ключу `applications:`.\
См. [Telemetry issue upgrading to ecto 3.0 #2793](https://github.com/elixir-ecto/ecto/issues/2793#issuecomment-436413037)

# 079
## Обработка ошибки валидации
В ветке обрабатывающей ошибку валидации нужно добавить отображение формы и текста ошибки:
```Elixir
  {:error, changeset} ->
    render conn, "new.html", changeset: changeset
```
Что бы пользователь видел ошибку, в шаблон формы нужно добавить специальный тег:
```Elixir
	<%= error_tag f, :title %>
```
он отображает ошибку валидации поля `title`

# 080
## CSS
Файл `web/static/css/app.css` содержит стили подключаемые ко всем страницам приложения.
Например, что бы сделать сообщение об шибке красным, можно прописать 
стиль для соответсвующего класса в `app.css`.

# 081-082
## Ecto.Repo all
При успешной отправке формы, нужно отобразить список всех тем. 
Что бы реализовать данную функциональность, нужно использовать функцию
`all/2` которая вытаскивает все записи удовлетворяющие запросу (см.[hexdocs.pm all/2](https://hexdocs.pm/ecto/Ecto.Repo.html#c:all/2)).\
Пример:
```Elixir
# Fetch all post titles
query = from p in Post,
     select: p.title
MyRepo.all(query)
```
Если запустить iex, можно получить список тем передав в функцию модуль `Discuss.Topic`.
Пример:
```
iex(1)> Discuss.Repo.all(Discuss.Topic)
[debug] QUERY OK source="topics" db=0.0ms
SELECT t0."id", t0."title" FROM "topics" AS t0 []
[
  %Discuss.Topic{
    __meta__: #Ecto.Schema.Metadata<:loaded, "topics">,
    id: 1,
    title: "JS frameworks"
  },
  %Discuss.Topic{
    __meta__: #Ecto.Schema.Metadata<:loaded, "topics">,
    id: 3,
    title: "Java EE6"
  },
  %Discuss.Topic{
    __meta__: #Ecto.Schema.Metadata<:loaded, "topics">,
    id: 4,
    title: "C++"
  }
]
``` 
Выполнение `Discuss.Repo.all(Discuss.Topic)` указывает Ecto, 
найти в БД сущность соответствующую модели 
и получить весь список записей.  

Вызов этой функции, нужно добавить в функцию `index` контроллера.
В контроллере уже присутствуют необходимый алиасы, т.о. запись будет
более компактной: `topics = Repo.all(Topic)`

# 083
## Шаблон для списка тем
Что бы отобразить страницу со списком полученным на предидущем шаге,
нужно использовать отдельный шаблон `web/templates/topic/index.html.eex`.
В нём для генерации тега списка можно использовать синтаксис for-генератора:
```Elixir
	<%= for topic <- @topics do %>
		<li class="collection-item">
			<%= topic.title %>
		</li>
    <% end %>
```
где в `@topics` попадает список тем, а с именем `topic` связывается 
отдельная тема и `<%= topic.title %>` выводит значение поля `title`.
Для кажого элемента исходного списка будет 
формироваться отдельный тег `<li>`. 

В контроллер нужно добавить вызов функции `render`:
```Elixir
render conn, "index.html", topics: topics
```


# 084
## Редирект из формы
При успешном создании новой темы, пользователь должен увидеть список тем.
Так же можно отобразить сообщение о том, что новая тема создана.
Для реализации нужно модифицировать код контроллера:
```Elixir
    case Repo.insert(changeset) do
      {:ok, post} ->
        conn
        |> put_flash(:info, "Topic Created")
        |> redirect(to: topic_path(conn, :index))
    ...
```
Для редиректа используется функция `redirect`, 
выполняющая перенаправление по указанному в `to:` URL 
(см.[redirect](https://hexdocs.pm/phoenix/Phoenix.Controller.html#redirect/2)).
Так же используется хелпер `put_flash/3` добавляющий к ответу текст
для отображения во всплывающей подсказке (см.[put_flash](https://hexdocs.pm/phoenix/Phoenix.Controller.html#put_flash/3))
Отображение подсказки "зашито" в макете `web/templates/layout/app.html.eex:26`,
где для получения значения используется функция `get_flash`.

# 085
## Кнопка для перехода на форму
Что бы пользователю стала доступна форма создания новой темы,
в интерфейс нужно добавить кнопку. Кнопка будет расположена на странице со списком всех тем,
в нижнем правом углу.
#### Material Icons
Для стилизации кнопки будут использованы иконки из набора "Material Icons".
На данном шаге они будут забираться с сервера в интернет.
К особенностям "Material Icons" относится то, что вид иконки задается текстом
в теле тега `<i>`: `<i class="material-icons">add</i>`. Иконка на кнопке в виде "плюса".
#### link
Для генерации правильной ссылки нужно вместо тега `<a>` использовать функцию `link`.
Функция сгенерирует тег `<a>`. 
И в ней можно использовать хелпер `topic_path` для формирования URL.
Что бы тегу были назначены определенные классы, в функцию нужно передать строковое значение
по ключу, например `class: "btn-floating btn-large"`.

# 086
## Router wildcards (параметры пути в URL)
Что бы реализовать функциональность редактирования темы, 
нужно отобразить соответствующую страницу редактирования.
По соглашению она должна быть доступна через GET запрос на URL вида `/topics/12/edit`,
где 12 - значение идентификатора выбранной темы. Т.о. идентификатор темы включен в путь
к странице.
Что бы получить к нему доступ нужно добавить URL в роутер и использовать 
подстановочный параметр на месте идентификатора темы. 
Например: `get "/topics/:id/edit", TopicController, :edit`, - здесь `:id` - параметр.

В контроллере нужно создать соответствующую функцию: `def edit(conn, %{"id" => topic_id) do`,
ожидающую, что в параметрах будет значение по _строковому_ ключу "id".

# 087-088
## Форма редактирования
#### Repo.get
Что бы отобразить текущее название темы для редактирования, нужно запросить его из БД.
Запро делается с помощью функции `Repo.get`, например:
`topic = Repo.get(Topic, topic_id)`.\
Затем полученную запись нужно отобразить в полях формы, это можно сделать используя отдельный шаблон.\
По соглашению функция `render` принимает `changeset`. Ченьжсет генерируется
непосредственно из полученной записи: `changeset = Topic.changeset(topic)`.
Затем выполняется рендер шаблона, в качестве параметра в шаблон передается ченьжсет и исходная запись.\
Новый шаблон с формой будет расположен в `web/templates/topic/edit.html.eex`.
Форма в шаблоне будет похожа на форму создания темы:
```Elixir
<%= form_for @changeset, topic_path(@conn, :update, @topic), fn f -> %>
```
Здесь стоит обратить внимние на применение хелпера: `topic_path(@conn, :update, @topic)`

Если в роутере будет указан ожидаемый путь `put "/topics/:id", TopicController, :update`
для функции `update`, то хелпер "вытащит" из записи `topic` значения полей указанные в пути.
Т.о. если исходная запись имела id=12 хелпер сформирует URL `/topics/12`. 
_Т.к. сейчас функции `update` не существует, при рендере будет ошибка._

Что бы форма начала отображатсья, нужно добавить путь в роутер: `put "/topics/:id", TopicController, :update`.

# 089
## Функция update контроллера 
Для обработки изменений в контроллер нужно добавить функцию `update` которая ожидает параметры:
идентификатор записи и саму измененную запись: 
`def update(conn, %{"id" => topic_id, "topic" => topic}) do`


## Изменение записи Repo.update
Функция `Repo.update` выполняет `UPDATE` запрос для соответсвующей сущности БД,
если в ченьжсете есть изменения относительно предидущего состояния.
Т.о. что бы сгенерировать ченьжсет нужно старое состояние записи и изменения из формы:
`changeset = Repo.get(Topic, topic_id) |> Topic.changeset(topic)`

Далее нужно выполнить апдейт и проверить валидность ченьжсета.
При успешном изменении будет отображено оповещение и список тем.

При ошибке должен произойдет возврат на форму и выдано сообщение об ошибке -
_на данном шаге еще не реализовано!_

# 090
#### Обработка ошибки проверки changeset
Если при проверке оказывается, что изменения невалидн, 
нужно снова отобразить форму с указанием поля в котором произошла ошибка.
Для этого в функцию рендер нужно передить запись считанную из БД.  

#### Кнопка перехода на форму редактирования
Что бы пользователь мог перейти на форму редактирования нужно, к каждой теме в списке,
добавить кнопку "Edit", которая будет открывать форму. 
Для этого нужно в шаблон списка добавить ссылки на форму редактирования, 
для каждой темы соответственно.
Для этого можно снова воспользоваться хелпером: `topic_path(@conn, :edit, topic)`, - здесь `topic`
элемент списка тем (функция используется внутри `for`).

# 091
## resources
Сейчас приложение следует RESTfull-соглашениям, это реализовано в роутере - типами HTTP запросов
и соответсвующими URL. Для реализации всей функциональности требуется 6 записей:
```Elixir
    get "/", TopicController, :index
    get "/topics/new", TopicController, :new
    post "/topics", TopicController, :create
    get "/topics/:id/edit", TopicController, :edit
    put "/topics/:id", TopicController, :update
    delete "/topics/:id", TopicController, :delete
```
В фенкисе есть хелпер позволяющий упростить этот код до отдной строки, при условии
следования соглашениям о запросах и именовании функций контроллера.
Т.о. можно заменить эти строки на:
```Elixir
    resources "/topics", TopicController
```
Этот хелпер даст ту же функциональность, за исключением доступа через "/", т.к.
такой путь нарушает соглашение. Доступ к списку (ф-ции `index`) теперь должен 
осуществляться через GET запрос к `/topics`, либо можно заменить первый параметр:
 `resources "/", TopicController` тогда доступ ко всем функциям тоже 
 будет идти без префикса "topics". 
 
# 092
## Repo.get! / Repo.delete! "bang" - версии функций
Все использованные в TopicController функции Ecto (кроме `all`) имеют "!"-версии.
Версии с суффиксом "!" отличаются тем, что при ошибке выполнения запроса порождают исключения.\
Для функции удаления темы это свойство будет удобно. Удаление можно выполнить в два шага:
попытаться запросить из БД запись по id, затем удалить её.\
Если записи с указанным id не существует, `get!` даст исключение которое феникс трансформирует в сообщени об ошибке (запись не существует).
Затем если `get!` сработало успешно, можно выполнить `delete!`, которая выдаст сообщение об ошибке если запись налья удалить.

# 093
## Кнопка "Delete"
Что бы пользователю было доступно удаление темы, нужно для каждого элемента списка сгенерировать кнопку.
Для этого в шаблон нужно доабвить код:
```Elixir
<%= link "Delete", to: topic_path(@conn, :delete, topic), method: :delete %>
```
он напоминает код кнопки "Edit", но в него добавлено указание HTTP метода "Delete": `method: :delete`.
Код который будет сгенерирован будет более сложным нежели просто тег `<a>` 
в теге будут присутствовать data-аттрибуты с указанием параметров запроса.

# 094-095
## OAuth
Для аутентификации в приложении планируется использовать OAuth через GitHub.
Алгоритм OAuth упрощенно выглядит так:
- по кнопке "Login" пользователя педиректит на GitHub.com
- на сайте GitHub отображается запрос авторизации для приложения "сайта"
- при подтвержении происходит редирект обратно, у URL добавляются параметры предоставляемой аутентификации через GitHub (код).
- используя код приложение может запросить данные пользователя у GitHub
- зарегистрировать нового пользователя в приложении
- аутентифицировать пользователя в приложении

## Überauth
Для OAuth существует модуль ueberauth, предоставляющий возможность аутентифицироваться через
различные источники (facebook, github...).\ 
Для его подключения нужно добавить две зависимости - саму библиотеку `ueberauth`
и стратегию аутентификации `ueberauth_github` соответствующую конкретному источнику.\
Так же нужно и добавить в `mix.exs` в конфиг приложения `application`.

# 096
## Регистрация на GitHub, настрокйка config.exs
Что бы GitHub предоставил сервис OAuth, нужно создать там свой аккаунт и зарегистрировать приложение.
Для этого в меню профиля нужно пройти в "Settings" - "Developer settings" - "OAuth Apps" и заполнить форму.
Важно, что бы в поле "Authorization callback URL" был специфичный для приложения URL.
Для данного приложения в это поле нужно ввести `http://localhost:4000/auth/github/callback`.
Другие поля формы имеют информационный характер.
После регистрации отобразится страница с "Client ID" и "Client Secret", 
которые будут нужны для настройки приложения.

В файл `config/config.exs` нужно добавить настройки провайдера аутентификации:
```Elixir
config :ueberauth, Ueberauth,
  providers: [
    github: { Ueberauth.Strategy.Github, []}
  ]
```
и данные полученные при регистрации:
```Elixir
config :ueberauth,  Ueberauth.Strategy.Github.OAuth,
  client_id: " *** Client ID *** ",
  client_secret: " *** Client Secret *** "
```

# 097
## OAuth callback
Из алгоритма OAuth видно, что в приложении должен быть контроллер который обрабатывает "Authorization callback URL".
Нужно создать `Discuss.AuthController` с функцией `callback` 
и подключенной, через механизм `plug` (см.[Plug](https://hexdocs.pm/phoenix/plug.html)) библиотекой `ueberauth`.

Так же нужно добавить новый путь в роутер.

#### scope "/auth"
В роутере, `scope` это макрос определяющий префикс (скоуп) для всех URL указанных внутри блока.
Пример:
```Elixir
  scope "/hello", Project do
    pipe_through :browser

    get "/world", HelloController, :index
  end
```
определяет, что GET запрос на `/hello/world` будет обработан функцией `index` в `HelloController`.
См.[scope](https://hexdocs.pm/phoenix/Phoenix.Router.html#scope/2)

#### pipe_through
Так же в примере выше можно обратить внимание на `pipe_through` - этот макрос определяет пайплайн
Через который будет пропущены данные запроса до его обработки контроллером.
Сам пайплайн (последовательность plug-ов) определен в роутере макросом `pipeline`.
См. [pipe_through](https://hexdocs.pm/phoenix/Phoenix.Router.html#pipe_through/1), [pipeline](https://hexdocs.pm/phoenix/Phoenix.Router.html#pipeline/2)

#### AuthController.request
Что бы запустить процесс аутентификации пользователь должен его инициировать запросом на специальный URL.
Эту функциональность предоставляет plug-ueberauth встраиваемый в контроллер в виде функции `request`.
Роутер должен передавать обработку GET `/auth/github` в эту функцию.\
В роутере не нужно указывать название конкретного провайдера ("github"), его можно
передавать в виде параметра, что бы проще было добавить ещё провайдера аутентификации, если потребуется.
В роутер нужно добавить следующий код:
```Elixir
  scope "/auth", Discuss do
    pipe_through :browser

    get "/:provider", AuthController, :request
  end
```
Так же в роутер нужно добавить путь к коллбэку: `get "/:provider/callback", AuthController, :callback`.
Таким образом последовательность будет такой - пользователь выполняет запрос GET `/auth/github`, 
затем ueberauth выполняет запрос на github, и github делает редирект на `/auth/github/callback`.

# 098
## Bug "Unable to access the user's email address"
Баг происходит в процессе аутентификации, если у пользователя не настроен публичный email.
Что бы это исправить, можно явно указать, что приложению требуется доступ к почте пользователя.
Это делается в `config/config.exs` параметром стратегии "default_scope":
`github: { Ueberauth.Strategy.Github, [default_scope: "user,user:email,public_repo"]}`

Теперь при переходе по [http://localhost:4000/auth/github/](http://localhost:4000/auth/github/)\
пользователь будет перенаправлен на github, к форме авторизации. 
После подтверждения произойдет редирект в приложение (но т.к. функциональность реализована не доконца, 
появится страница ошибки).\
В консоли можно увидеть залоггированные данные полученные функцией `callback`.

#### Сброс аутентификации
Если попытаться пройти аутентификацию повторно, то она будет проходить моментально, минуя форму на гитхабе.
Что бы воспроизвести все шаги процесса, можно отозвать доступ приложения из профиля github:
нужно перейти в "Personal settings" - "Applications" - "Authorized OAuth Apps". На вкладке перечислены все 
приложения прошедшие аутентификацию через github. 
Нужно найти имя под которым зарегистрировано данное и нажать "revoke".

# 099
## Миграция таблицы для регистрации пользователя приложения.
Данные полученные от провайдера OAuth нужно сохранить в БД.\
Для этого нужно сгенерировать новый файл миграции: `mix ecto.gen.migration add_users`.\
Будет создан файл `priv/repo/migrations/20190707184623_add_users.exs`.\
В файле нужно заполнить название и поля новой таблицы:
```Elixir
  def change do
    create table(:users) do
      add :email, :string
      add :provider, :string
      add :token, :string

      timestamps()
    end
  end
```
здесь, поле "email" будет хранить адрес почты пользователя, "provider" - название провайдера аутентификации и
"token" - токен, предоставленный провайдером при успешной аутентификации.
Функция `timestamps()` добавит поля хранящие таймстамп создания записи и таймстамп обновления.
Далее нужно выполнить миграцию: `mix ecto.migrate`.\
Таблица будет создана и будет иметь следующую структуру (postgres):
```SQL
create table users
(
	id bigserial not null
		constraint users_pkey
			primary key,
	email varchar(255),
	provider varchar(255),
	token varchar(255),
	inserted_at timestamp(0) not null,
	updated_at timestamp(0) not null
)
;
```

# 100 
## Модель сущности user
Что бы оперировать с данными пользователя требуется создать модель: `web/models/user.ex`.
По структуре модуль бдует индетичен модели "topic", отличаясь лишь количеством полей, а
так же функцией `timestamp` применяемой как и в файле миграции.

# 101
## Наполнение записи User из параметра auth
В функции `callback` AuthController происходит деструктуризация conn, что бы извлечь 
параметры аутентификации: `{assigns: %{ueberauth_auth: auth}} = conn`.\
В записи "auth" содержатся все необходимые данные, что бы заполнить модель User.
Затем можно сгененрировать ченьжсет, что бы записать данные в БД.

# 102
## Запись User в БД
При вызове `callback` необходимо создавать записи для новых пользователей, а для существующих
делать обновление.
Примем, что аккаунт должен иметь уникальный email. 
Это необходимо для идентификации уникального пользователя.\
Т.о:
- Если пользователь аутентифицирован впервые - INSERT
- Если пользователь аутентифицирован повторно - UPDATE
- За уникальный ключ принимается email

#### defp - приватная функция
Эти операции имеет смысл выделить в приватную функцию `insert_or_update_user`, 
такая функция объявляется ключевым словом `defp`.
Она будет доступна только внутри модуля в котором объявлена.

#### Repo.get_by
Для проверки на существования записи пользователя 
можно применить функцию [Repo.get_by](https://hexdocs.pm/ecto/Ecto.Repo.html#c:get_by/3)
Функция принимает модель и ассоциативный массив в котором ключем являестся атом-поле модели 
и некоторое значение. Запрос будет выбирать единственную запись у которой 
поле и значение совпадают с имеющимися в массиве. Если запись не найдена, функция
вернет `nil`.\
Значение `nil` будет означать, что нужно выполнить вставку новой записи, либо,
если функция вернула данные, нужно выполнить обновление (таймстамп в данном случае).

# 103
## Хранение id пользователя в cookies
Результатом выполнения `insert_or_update_user` так или иначе будет запись идентифицирующая 
пользователя.\
При вставке данных модели в БД, происходит генерация уникального идентификатора (автоинкрементный ключ),
т.о. запись `User` имеет уникальный числовой идентификатор, который можно использовать
как id в сессии. Для этого его нужно поместить в cookies, и по наличию там этого идентификатора
авторизовать пользователя.

# 104
#### Функция "signin"
В приватной функции `signin` будут объединены шаги описанные в пунктах 102 и 103.\
Функция `insert_or_update_user` возвращает значение согласующееся с результатом `Repo.insert`.
Т.е. пару первым элеметом в которой будет атом `:ok` - если успешно, `:error` - в случае ошибки.\
Ошибка на данном шаге не предусмотрена бизнес-логикой (может возникнуть только при каком то сбое БД).
Т.о. обработка ошибки сводится к редиректу пользователя на индекс и отображению сообщения о
"неизвестной ошибке при аутентификации": `put_flash(conn, :error, "Error signing in")`.

В случае успеха, выводится приветственное сообщение, 
`user.id` записывается в cookies, 
затем выполняется редирект на главную страницую.\
Запись в cookies выполняется через функцию работы с сессией `put_session(:user_id, user.id)`.
**Сессионные данные будут зашифрованы, это послужит защитой от фальсификации идентификатора "user_id"**

# Vagrant
В репозиторий добавлен Vagrantfile с PostgreSql. 
При работе с проектом использовалась старая версия Vagrant 1.9.1 (windows + VirtualBox 4.3.20), 
которой требовался "патч" в 10 строке Vagrantfile:
```
#patch for my outdated version of vagrant
Vagrant::DEFAULT_SERVER_URL.replace('https://vagrantcloud.com')
```
Для работы с актуальной версией, убрать или закомментировать.

# 105
## Plugs
[Plug](https://hexdocs.pm/phoenix/plug.html) - это спецификация композируемых модулей в веб приложениях.
Композиция производится через структуру "соединение" `%Conn{}` которую каждый plug принимает в качестве аргумента
и возвращает как результат. Соединение одновременно несёт в себе данные HTTP-запроса и ответа.
Существует две разновидности plug-ов: [функции](https://hexdocs.pm/phoenix/plug.html#function-plugs) 
и [модули](https://hexdocs.pm/phoenix/plug.html#module-plugs).\
Примером функции plug-а могут служить функции обработки запроса, определенные в контроллере:
```Elixir
  def index(conn, _params) do # принимает первый аргумент Conn
    topics = Repo.all(Topic)
    render conn, "index.html", topics: topics # возвращает Conn
  end
```

Модуль-plug должен содержать функции:
- `init/1` инициализация параметров - вызывается 1 раз, при запуске приложения
- `call/2` первый арг. - conn, второй арг. - параметры, результат - conn; т.о. `call` представляет собой функцию-plug.

Параметры которые вернёт функция `init` будут передаваться вторым аргументом
в `call` при каждом её вызове.\
Модуль нужен если plug будет использоваться в нескольких контроллерах.

Plug удобно использовать для "обогащения" conn какими-либо данными.
Например права пользователя на доступ.

# 106
## Plug SetUser
#### Выражение `cond`
[cond](https://elixir-lang.org/getting-started/case-cond-and-if.html#cond) 
аналогичен `if`, но может иметь более одной условия ветвления. Если условные выражения во всех ветвях
вернули `false` или `nil` будет выброшена ошибка `CondClauseError`. Значением всего выражения `cond` 
становится значение вычисленное в выполненной ветви.

#### особенности булева оператора `&&`
В эликсире за ложные значения приняты: false и nil, 
а значением всего выражения становится результат выполнения последней функции.
Оператор `&&` является "ленивым" (точнее [short-circuit](https://en.wikipedia.org/wiki/Short-circuit_evaluation)) оператором,
т.о. вычисление правой части происходит только если значение в левой части истинно.
Т.о. можно выполнить сложную проверку:
```Elixir
	cond do
		user = user_id && Repo.get(User, user_id) -> 
			... # успешно
	end
```     
здесь сначала производится вычисление выражения `user_id && Repo.get(User, user_id)`, 
если `user_id` не определено (nil), то `Repo.get` не выполняется, и значением всего выражения становится nil;
либо значением выражения будет результат выполнения `Repo.get(User, user_id)`.
Затем `user` присваивается полученное значение и если оно истинно (не nil) выполняется ветвь. 

#### функция `Plug.Conn.assign/3`
Функция [assign](https://hexdocs.pm/plug/Plug.Conn.html#assign/3) сохраняет пользовательские данные 
в поле `assigns` (хэшмэп) структуры Conn. Данные в `assigns` сохраняются на протяжении цикла обработки 
запроса, и все подключенные Plug-и имеют к ним доступ.\
Plug "SetUser" будет сохранять данные пользователя в `assigns` по ключу `:user`: 
```Elixir 
	assign(conn, :user, user) 
```

# 107 
## pipeline
Что бы включить plug в цикл обработки запроса, нужно добавить его в тело макроса `pipeline` в роутере:
```Elixir 
  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Discuss.Plugs.SetUser
  end
```
в макросе уже есть некоторые plug-и добавленные автоматически при генерации проекта - это функции, 
они определены как атомы, например: `plug :accepts, ["html"]`.\
Подключение Plug-модуля выглядит иначе - нужно указать полное имя модуля `plug Discuss.Plugs.SetUser`. 

Когда происходит обработка запроса, plug-и применяются в последовательности, в которой они указаны в пайплайне.

Теперь, если добавить в контроллер `IO.inspect(conn.assigns)` можно увидеть, что при запросе страницы
отображается запись содержащая значение `%Discuss.User`.

#### использование *_path хелперов с путями содержащими подстановочные значения
Что бы воспользоваться хелпером, например `auth_path` для пути `:request` нужно добавить дополнительный параметр,
который будет использован как изменяющаяся часть URL: `auth_path(@conn, :request, "github")`. Т.о. в данном примере
`:provider` будет заменен на "github" и URL будет "http://localhost:4000/auth/github".

# 108
## выход (signout) из приложения
В этой реализации, plug получает данные пользователя из сессии. Что бы пользователь мог выйти из системы, 
нужно очистиь данные в сессии.
Для этого нужно создать функцию контроллера (например `signout` в `AuthController`), 
которая при определенном запросе очищает данные, затем перенаправляет пользователя на индекс.
#### configure_session
Для очистки данных нужно использовать специальную функцию 
[configure_session/2](https://hexdocs.pm/plug/Plug.Conn.html#configure_session/2)
с параметрами `(conn, drop: true)`. Параметр "drop" - удалить куки сессии.

# 109-110
## Ограничение доступа в приложении
**Любой пользователь**, даже не зарегистрированный, должен иметь возможность просмотреть список тем и сообщения в теме.
Любой **зарегистрированный пользователь** должен иметь доступ к форме создания новой темы.
Зарегистрированный **пользователь являющийся создателем** темы должен иметь возможность изменить её название либо удалить. 
#### свободный доступ к индекс-странице и сообщениям в теме
При реализации контроля доступа, нужно оставить свободный доступ к списку тем и сообщениям в каждой теме.
Эта функциональность реализуется двумя функциями контроллера, т.о. их можно выделить в отдельную группу.
Для остальных функций нужно реализовать plug, который будет запускаться после роутера, когда уже ясно
какая именно функция контроллера должна обработать запрос.
## require_auth plug
Для применения ограничений нужно создать новый plug. В нём будет производиться проверка, есть ли в `conn.assigns`
значение по ключу `user`. Существование такого значения говорит об успешной аутентификации и plug просто
передает обработку запроса далее - контроллеру в данном случае, либо последующему в конвеере plug-у.
Если значение `user` отсутсвует, нужно сделать редирект на индекс и вывести сообщение об ошибке, прервав обработку запроса.
plug может прервать дальнейшую обработку запроса функцией [halt/1](https://hexdocs.pm/plug/Plug.Conn.html#halt/1):
```Elixir
      conn
      |> put_flash(:error, "You must be logged in.")
      |> redirect(to: Helpers.topic_path(conn, :index))
      |> halt()
```  
здесь, после выполнения данного кода сразу будет выполнен редирект, дальнейшая обработка `conn` не будет выполнена.

# 111
## макрос plug в контроллере
Подключить plug таким образом как указано в предидущем пункте, можно непосредственно в контроллере TopicController.
Для подключения используется одноименный макрос `plug`:
```Elixir
  plug Discuss.Plugs.RequireAuth when action in [:new, :create, :edit, :update, :delete]
```
здесь сначала указано имя plug-модуля, а затем предикат `when action in` указывающий условие срабатывания plug-а, т.к.
ограничить доступ нужно только к определенным функциям.

Теперь функции edit/delete будут недоступны для не аутентифицированных пользователей, 
они будут видеть сообщение "You must be logged in.".

# 112
## Привязка темы к пользователю
Что бы пользователь мог редактировать/удалять только свои темы, нужно связать учетную запись с темой.
Для этого в таблицу тем нужно добавить колонку с идентификатором пользователя.
Для реализации изменений в таблице нужно создать файл миграции:
```cmd
mix ecto.gen.migration add_user_id_to_topics
```

# 113
А файл миграции нужно добавить код:
```Elixir
  def change do
    alter table(:topics) do
      add :user_id, references(:users)
    end
  end
```
Здесь `references` указывает, что поле `user_id` связывает запись из `topics` с записью в `users`.
Теперь можно выполнить миграцию:
```cmd
mix ecto.migrate
```
Если посмотреть структуру БД, после выполнения, 
видно что в таблице появился внешний ключ `user_id`:
```SQL
create table topics
(
	id bigserial not null
		constraint topics_pkey
			primary key,
	title varchar(255),
	user_id bigint
		constraint topics_user_id_fkey
			references users
)
;
```

# 114   
## Связка (отношения) моделей
Что бы феникс получил доступ к изменениям в БД, 
нужно модифицировать соответсвующие модели.
В схему `web/models/user.ex` нужно добавить строку:
```Elixir
    has_many :topics, Discuss.Topic
```
где указан тип отношения (один-ко многим), имя поля и модуль в котором описана связываемая модель.
В схеме `web/models/topic.ex` нужно добавить:
```Elixir
    belongs_to :user, Discuss.User
```
здесь аналогично указывается тип отношения (принадлежность), поле и модель.

Теперь можно проверить код в IEX:
```cmd 
iex -S mix
iex(1)> Discuss.Repo.get(Discuss.User, 1)
```
Команда вернет структуру:
```Elixir 
%Discuss.User{
  id: 1,	
  topics: #Ecto.Association.NotLoaded<association :topics is not loaded>,
  # ...
}
```
но в поле `topics` будет значение `#Ecto.Association.NotLoaded<association :topics is not loaded>`
т.к. по умолчанию феникс не подгружает связи.
Нужно заметить, что в БД на данный момент будут отсутсвовать связи темы и пользователя.

# 115-116
## Функция привязки созданной темы
Для связки двух моделей в Ecto функция [build_assoc/3](https://hexdocs.pm/ecto/Ecto.html#build_assoc/3).
Она находится непосредственно в модуле Ecto (не Ecto.Query).
Функция принимает 3 аргумента (последний из которых не обязателене). 
Первым аргументом передается исходная структура, вторым - связанная с ней.
Функция возвращает второй аргумент изменённый так, что бы в нём была зафиксирована
связь (значение внешнего ключа).

Реализацию нужно добавить в TopicController в функцию `create`:
```Elixir
    changeset = conn.assigns.user
      |> build_assoc(:topics)
      |> Topic.changeste(topic)
```
этот код позволяет получить ченьжсет в котором уже есть связь с пользователем.
Теперь, при создании новой темы, в запись добавляется внешний ключ `user_id`.



